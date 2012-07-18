#!/usr/bin/env ruby

require 'em-websocket'
require 'json'
require 'socket'
require 'yajl'

EventMachine.run {
  # @channel = EM::Channel.new

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
        puts "Chunk received: #{data.size}: \n<<!#{data}!>>"
        # puts "--\n Buffer was: \n<<!#{@data}!>>"
        @data << data
        @parser.parse(@data)
      end
    end
    
    def object_parsed(obj)
      # puts "Sometimes one pays most for the things one gets for nothing. - Albert Einstein"
      # puts "\tObject created: #{@data.size}: \n<<!#{obj.to_json}!>>"
      # puts obj.inspect
      @data = ""
      @channel.push obj.to_json
      puts "Publishing #{obj.to_json}"
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

  EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8181, :debug => true) do |ws|

    ws.onopen {
      channel = EM::Channel.new
      comlink = EventMachine::connect '127.0.0.1', 11142, Watcher
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
}