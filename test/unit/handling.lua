#!/usr/bin/env lua

local args = nil
do
  local cli = require "cli"
  cli:set_name("grind_test.lua")
  cli:add_arg("grind_ROOT", "path to where grind/scripts can be found", "root_path")
  cli:add_opt("-i FILE", "path to a text file which will be grinded", "input_path")
  cli:add_opt("-n NR", "the number of requests to generate", "nr_requests", "1")

  args = cli:parse_args()
  if not args then
    return
  end
end


package.path = "../../scripts/?.lua;" .. package.path

require "grind"

set_paths(args["root_path"])
grind.start()

report_mem_usage()

log("Running " .. args["nr_requests"] .. " grind requests.", log_level.info)
for i=1,tonumber(args["nr_requests"]) do
  local content = ""
  if args["input_path"] ~= "" then
    fh = io.open(args["input_path"], "r")
    content = fh:read("*all")
    fh:close()
  else
    content =
      [==[
      Jun 25 12:31:44 cornholio dakapi: [I] Channel[translations]: closing ADOOKEN
      Jun 25 12:31:46 cornholio dakapi: [I] db_manager: how do YOU DOOGEN?
      Jun 25 12:31:46 cornholio dakapi: [I] {1234567} connection: how do YOU DOOGEN?
      Jun 25 12:31:46 cornholio dakapi: [I] x: connection: how do YOU DOOGEN?
      ]==]
  end

  grind.handle(content)

  report_mem_usage()
end

grind.stop()
collectgarbage()

report_mem_usage()
