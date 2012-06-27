#!/usr/bin/env ruby

require 'em-websocket'
require 'json'
require 'socket'
require 'yajl'

EventMachine.run {
  @channel = EM::Channel.new

=begin
  Thread.new {
    s = TCPSocket.open("127.0.0.1", 11144)

    leftovers = ""
    while buf = s.recv(512) do
      # puts buf
      buf = leftovers + buf
      leftovers = ""
      puts "got #{buf.size} bytes of data to process"
      # puts buf
      i = buf =~ /\%GRIND\<(.+)\>GRIND\%/
      puts i
      while i != nil do
        puts "ooh, captured something! "
        m = $~.captures.first
        puts m

        # begin
          json = JSON.parse(m)
          @channel.push json.to_s
        # rescue Exception => e
          # puts e
        # end

        # buf.slice![i..m.size+7]
        lp = buf[0,i]
        rp = buf[m.size+14,buf.size]
        buf = lp + rp

        puts "LP: #{lp}"
        puts "RP: #{rp}"
        puts "BUFFER AFTER SLICING: \n#{buf}\n\n"
        i = buf =~ /\%GRIND\<(.+)\>GRIND\%/

        puts "checking for another message"
      end
      # index = buf.index("%GRIND%")
      # while index do
      #   m = buf[0..index]

      #   begin
      #     json = JSON.parse(m)
      #     @channel.push json.to_s
      #   rescue Exception => e
      #   end

      #   buf = buf[index+7..-1]
      #   index = buf.index("%GRIND%")
      # end

      leftovers = buf
      puts "\t#{leftovers.size} bytes are left over"
      if leftovers.size > 0
        puts leftovers
      end
    end

    puts "closing down"

    s.close
  }
=end

  module Watcher 
    def self.set_channel(c)
      @@channel = c
    end

    def post_init
      @mtx = Mutex.new
      @data = ""
      @parser = Yajl::Parser.new()
    end
    
    def receive_data(data)
      @mtx.synchronize do
        @data << data
        puts data
        @parser.parse(@data)
      end
    end
    
    def object_parsed(obj)
      # @mtx.synchronize do
        puts "Sometimes one pays most for the things one gets for nothing. - Albert Einstein"
        puts obj.inspect
        @data = ""
        @@channel.push obj.to_json
      # end
    end    

    def connection_completed
      # once a full JSON object has been parsed from the stream
      # object_parsed will be called, and passed the constructed object
      @parser.on_parse_complete = method(:object_parsed)
    end    

    def unbind
      EventMachine::stop_event_loop
    end
  end

  EventMachine::connect '127.0.0.1', 11144, Watcher
  Watcher.set_channel(@channel)
  EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8181, :debug => true) do |ws|

    ws.onopen {
      sid = @channel.subscribe { |msg| ws.send msg }
      # @channel.push "#{sid} connected!"

      ws.onmessage { |msg|
        # @channel.push "<#{sid}>: #{msg}"
      }

      ws.onclose {
        @channel.unsubscribe(sid)
      }
    }

  end

  puts "Server started"
}