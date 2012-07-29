require 'sinatra/base'
require 'sinatra/content_for'
require 'sass'
require 'json'
require 'em-websocket'
require 'yajl'
require 'socket'

Settings = JSON.parse(File.read(File.join(File.dirname(__FILE__), "config.json")))

module Watcher 
  def set_channel(c)
    @channel = c
  end

  def post_init
    @mtx = Mutex.new
    @data = ""
    @parser = Yajl::Parser.new()
  end
  
  def receive_data(data)
    @mtx.synchronize do
      # puts "Chunk received: #{data.size}: \n<<!#{data}!>>"
      # puts "--\n Buffer was: \n<<!#{@data}!>>"
      @data << data
      begin
        @parser.parse_chunk(@data)
      rescue Exception => e
        puts "ERROR: #{e.message}"
        puts "Gracefully emptying buffer"
        File.open("dump", "w") { |f| f.write("#{e.message}\n\n#{@data}") }
        # @data = ""
        # EventMachine::stop_event_loop
      end
    end
  end
  
  def object_parsed(obj)
    @data = ""
    @channel.push obj.to_json
    # puts "Publishing #{obj.to_json}"
  end    

  def connection_completed
    # once a full JSON object has been parsed from the stream
    # object_parsed will be called, and passed the constructed object
    @parser.on_parse_complete = method(:object_parsed)
    puts "connected to grind"
    @channel.push({ notice: "connected" }.to_json)
  end    

  def unbind
    @channel.push({ notice: "disconnected" }.to_json)
    # EventMachine::stop_event_loop
  end
end

def start_websocket_server()

  EventMachine::WebSocket.start(
    :host => Settings["watcher"]["address"], 
    :port => Settings["watcher"]["port"],
    :debug => false) do |ws|

    ws.onopen {
      channel = EM::Channel.new
      comlink = EventMachine::connect Settings["grind"]["address"], Settings["grind"]["port"], Watcher
      puts comlink.error?
      comlink.set_channel(channel)
      sid = channel.subscribe { |msg| ws.send msg }

      ws.onmessage { |msg|
        puts "Message received from <#{sid}>: #{msg}"
        comlink.send_data(msg)
      }

      ws.onclose {
        puts "Channel closing"
        channel.unsubscribe(sid)
        channel = nil
        comlink.close_connection
        # @comlink.remove_terminal(t)
      }
    }

  end

  puts "Server started"  
end

class WatcherUI < Sinatra::Base
  configure do
    enable :sessions
    include Sinatra::ContentFor

    set :cfg_path, File.join(File.dirname(__FILE__), "config.json")
    @@settings = JSON.parse(File.read(settings.cfg_path))
  end

  before do
    if !@@settings then
      @@settings = JSON.parse(File.read(settings.cfg_path))
    end

    @settings = @@settings
  end

  get '/css/:sheet.css' do |sheet|
    content_type 'text/css', :charset => 'utf-8'
    scss :"#{sheet}", :views => './public/css'
  end

  get '/skins/:skin' do |skin|
    session[:skin] = skin
    redirect back
  end

  get '/settings' do
    erb :settings
  end
  post '/settings' do
    File.open(settings.cfg_path, "w") { |f|
      f.write(params.to_json)
    }

    erb :settings
  end

  get '/' do
    erb :index  
  end

  get '/:group/:klass/:view' do |*args|
    @group, @klass, @view = args

    erb :view
  end

  get '/:group/:klass' do |group, klass|
    @group, @klass = group, klass

    erb :klass
  end


  get '/:group' do |group|
    puts "in /:group with group: #{group}"
    @group = group
    erb :group
  end

  helpers do
    def skin
      session[:skin] || "minimal"
    end
  end
end

EventMachine.run do
  start_websocket_server

  WatcherUI.run!
end
