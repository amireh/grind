#!/usr/bin/env ruby

gem 'yajl-ruby'
gem 'eventmachine'
gem 'mongo'
gem 'sinatra'

require 'json'
require 'socket'
require 'yajl'
require 'yaml'
require 'mongo'
require 'eventmachine'
require 'sinatra/base'

Settings = JSON.parse(File.read(File.join(File.dirname(__FILE__), "config.json")))

class Keeper < EventMachine::Connection
  def set_channel(c)
    @channel = c
  end

  def post_init
    @mtx = Mutex.new
    @data = ""
    @parser = Yajl::Parser.new()
    @parser.on_parse_complete = method(:object_parsed)

    @dba = Mongo::Connection.new("localhost")
    @dbh = @dba.db("grind")

    subscribe

    # puts "Connected"
  end

  def subscribe
    send_data({ id: "subscribe", args: { group: "*", klass: "*", view: "*" } }.to_json)
  end
  
  def receive_data(data)
    @mtx.synchronize do
      @data << data
      @parser.parse_chunk(@data)
    end
  end
  
  def object_parsed(obj)
    @data = ""
    if obj.has_key?("command")
      if obj["command"] == "purge" then
        @dbh.collection_names.each { |c| @dbh[c].remove() }
      end
      return
    end
    entry = {}
    obj["entry"].each { |datum|
      entry[datum[0]] = datum[1]
    }
    @dbh[obj["group"]].insert({ klass: obj["klass"], view: obj["view"], entry: entry })
    puts "Received #{obj}"
  end    

  def connection_completed
    puts "Connected to grind"
  end    

  def unbind
    puts "Disconnected from grind"
    EventMachine::stop_event_loop
    cleanup
  end

  def cleanup
    @dba.close
  end
end

class Tentacle < Sinatra::Base
  configure do
    @@dba = Mongo::Connection.new("localhost")
    @@dbh = @@dba.db("grind")

    set :port, Settings["api"]["port"].to_i
    # set :server, "webrick"

    puts "Keeper API will be running on port #{settings.port}"
  end
  before do
    headers 'X-Frame-Options' => ''
    headers 'Access-Control-Allow-Origin' => '*'
  end
  get '/:group/:klass/:view' do |*args|
    content_type :json

    group, klass, view = args
    limit = params[:limit] || 500
    docs = []
    @@dbh[group].find({ klass: klass, view: view }).limit(limit.to_i).each { |doc|
      entry = { group: group, klass: klass, view: view, entry: {} }
      doc["entry"].each_pair { |k,v| entry[:entry][ k ] = v }
      docs << entry
    }

    docs.to_json
  end
  post '/:group/:klass/:view' do |*args|
    content_type :json

    group, klass, view = args
    limit = params[:limit] || 500

    docs = []
    puts "Querying for: #{params[:query]}"
    query = { klass: klass, view: view }
    if params[:query] then
      params[:query].each_pair { |field, value|
        query[field] = JSON.parse(value)
      }
    end
    @@dbh[group].find(query).limit(limit.to_i).each { |doc|
      entry = { group: group, klass: klass, view: view, entry: {} }
      doc["entry"].each_pair { |k,v| entry[:entry][ k ] = v  }
      docs << entry
    }

    docs.to_json
  end

  def self.cleanup
    @@dba.close
  end
end


EventMachine.run do
  keeper = EventMachine::connect Settings["grind"]["address"], Settings["grind"]["port"], Keeper
  puts "Keeper running!"
  Tentacle.run!
end

Tentacle.cleanup