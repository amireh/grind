local cli = require 'cliargs'
local socket = require "socket"
local json = require "dkjson"
local signal = require "signal"

local args = nil
do
  cli:set_name("watcher_test.lua")
  cli:add_arg("GROUP", "application group identifier", "group")
  cli:add_arg("KLASS", "klass identifier", "klass")
  cli:add_arg("VIEW", "view identifier", "view")
  cli:add_opt("-h, --host", "the host IP on which grind is running", "host", "127.0.0.1")
  cli:add_opt("-p, --port", "the port on which grind is running", "port", 11144)
  cli:add_opt("-t, --timeout=VALUE", "amount of milliseconds to wait before interrupting the connection", "tt", 100)

  args = cli:parse_args()
  if not args then
    return
  end
end

local client = assert(socket.connect(args.host, args.port))
client:setoption("keepalive", true)
client:setoption("tcp-nodelay", true)
client:settimeout(args.tt / 1000)

local running = true
local cleanup = function()
  print("SIGINT was received - shutting down")
  client:close()
  client:shutdown()
  client = nil
  running = false
end

signal.signal("SIGINT", cleanup)
signal.signal("SIGTERM", cleanup)

local cmd_args = args
cmd_args.host = nil
cmd_args.port = nil
cmd_args.tt = nil

client:send(json.encode({ id = "subscribe", args = cmd_args }))

while running do
  if not client then break end

  local data,err,partial = client:receive('*a')
  if data then
    print(data)
  end
  if partial and #partial > 0 then
    print(partial)
  end
  if err and err ~= "timeout" then
    print("ERROR: " .. err)
    return cleanup()
  end
end

if client then
  client:close()
  client:shutdown()
end
