local cli = require 'cliargs'
local socket = require "socket"
-- local json = require "dkjson"
local json = require "cjson"

local args = nil
do
  cli:set_name("api_test.lua")
  cli:add_arg("COMMAND", "the command identifier", "cmd")
  cli:add_opt("-g, --group=GROUP", "application group identifier", "group")
  cli:add_opt("-k, --klass=ID", "klass identifier", "klass")
  cli:add_opt("-v, --view=ID", "view identifier", "view")
  cli:add_opt("-h, --host=HOST", "the host IP on which grind is running", "host", "127.0.0.1")
  cli:add_opt("-p, --port=PORT", "the port on which grind is running", "port", 11142)
  cli:add_opt("-t, --timeout=MS", "amount of milliseconds to wait before interrupting the connection", "tt", 1)
  cli:add_flag("-R, --result-only", "displays the result without any extra data", "ro", false)
  

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
-- if data then
  -- print(data)
-- end
if partial and #partial > 0 then
  data = (data or "") .. partial
end
if err and err ~= "timeout" then
  print("ERROR: " .. err)
end

if args["ro"] then
  function table.dump(t, indent)
    if not indent then indent = 0 end
    local padding = ""
    for i=0,indent do padding = padding .. "  " end
    for k,v in pairs(t) do
      if type(v) == "table" then 
        table.dump(v, indent + 1)
      else
        print(padding .. tostring(k) .. " => " .. tostring(v))
      end
    end
  end  
  table.dump(json.decode(data).result)
else
  print(data)
end
client:close()
client:shutdown()