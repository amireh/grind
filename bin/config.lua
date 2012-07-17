#!/usr/bin/env lua

-- This needs to point to the directory that contains grind.lua
local root = "/home/kandie/Workspace/Projects/grind/scripts"
local cfg = {
  kernel = {
    feeder_interface = "127.0.0.1",
    watcher_interface = "127.0.0.1",
    watcher_port = "11142"
  }
}

package.path = "?.lua;" .. package.path -- for absolute paths
package.cpath = "/usr/local/lib/?.so;" .. package.cpath

require "lfs"
require "lua_grind"

local start = function(root)
  package.path = root .. "/../?.lua;" .. package.path -- for relative paths
  package.path = root .. "/?.lua;" .. package.path

  grind.config = cfg
  grind.init(root)
end

local load = function(filepath)
  if not lfs.attributes(filepath .. ".lua", "mode") then return false end

  require(filepath)

  return true
end

if load(root .. "/grind") then
  return start(root)
end

-- Look for the scripts in some system paths:
local default_paths = {
  "/usr/lib/lua",
  "/usr/lib/lua/5.1",
  "/usr/local/lib/lua",
  "/usr/local/lib/lua/5.1",
  "/opt/grind/scripts",
  "/usr/local/grind/scripts",
  "/usr/local/src/grind/scripts",  
}

for _,path in ipairs(default_paths) do
  if load(path .. "/grind") then
    return start(path)
  end
end

local msg = 
  "ERROR: Unable to find grind's main script, this is where I looked:" ..
  "\n  1. " .. root .. "/grind.lua"

for i, path in ipairs(default_paths) do
  msg = msg .. "\n  " .. i+1 .. ". " .. path .. "/grind.lua"
end

error(msg)