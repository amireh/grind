#!/usr/bin/env lua

local args = nil
do
  local cli = require "cliargs"
  cli:set_name("grind_test.lua")
  cli:add_arg("PORT", "the feeder port", "port")
  cli:add_opt("-i FILE", "path to a text file which will be grinded", "input_path")

  args = cli:parse_args()
  if not args then
    return
  end
end


local socket = require 'socket'
local client = assert(socket.connect("127.0.0.1", args.port))
client:setoption("keepalive", true)
client:setoption("tcp-nodelay", true)
client:settimeout(5 / 1000)

-- local size = 2^13      -- good buffer size (8K)
local size = 1024
fh = io.open(args["input_path"], "r")
while true do
  local block = fh:read(size)
  if not block then break end
  client:send(block)
end

fh:close()
client:close()
client:shutdown()