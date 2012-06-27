require 'socket'

s = TCPSocket.open("127.0.0.1", 11144)
running = true

Signal.trap("SIGINT") {
  puts "INTERRUPTED"
  running = false
}

while line = s.recv(512) do
  break if !running
  puts line  
end