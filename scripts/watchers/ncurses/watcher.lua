package.cpath = "/usr/local/lib/?.so;" .. package.cpath
local socket = require("socket")
require 'signal'
local client = assert(socket.connect("127.0.0.1", "11144"))
client:setoption("keepalive", true)
client:setoption("tcp-nodelay", true)

running = true
signal.signal("INT", function()
  print("SIGINT was received - shutting down")
  client:close()
  client:shutdown("receive")
  running = false
end)
client:settimeout(0)
-- signal.raise("SIGINT")
while running do
  -- socket.sleep(1)
  -- print("zZz")
  local data,err,partial = client:receive('*a')
  if data then
    print(data)
  end
  if partial and #partial > 0 then
    print(partial)
  end
  if err and err ~= "timeout" then
    print("ERROR: " .. err)
  end
end