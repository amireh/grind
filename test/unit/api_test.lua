local cli = require 'cliargs'
local socket = require "socket"
local json = require "dkjson"

local args = nil
do
  cli:set_name("api_test.lua")
  cli:add_arg("COMMAND", "the command identifier", "cmd")
  cli:add_opt("-g, --group=GROUP", "application group identifier", "group")
  cli:add_opt("-k, --klass=ID", "klass identifier", "klass")
  cli:add_opt("-v, --view=ID", "view identifier", "view")
  cli:add_opt("-h, --host=HOST", "the host IP on which grind is running", "host", "127.0.0.1")
  cli:add_opt("-p, --port=PORT", "the port on which grind is running", "port", 11141)
  cli:add_opt("-t, --timeout=MS", "amount of milliseconds to wait before interrupting the connection", "tt", 1)
  cli:add_opt("-a, --arg=\"KEY=VAL\"", "arbitrary arguments", "extra_args", {})

  args = cli:parse_args()
  if not args then
    return
  end
end

local client = assert(socket.connect(args.host, args.port))
client:setoption("keepalive", true)
client:setoption("tcp-nodelay", true)
client:settimeout(args.tt / 1000)

local cmd_args = args
cmd_args.host = nil
cmd_args.port = nil
cmd_args.tt = nil

client:send(json.encode({ id = args.cmd, args = cmd_args }))

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

client:close()
client:shutdown()