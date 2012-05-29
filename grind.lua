package.cpath = "/usr/local/lib/?.so;" .. package.cpath

local ncurses = require "lua_ncurses"
local inotify = require "inotify"

-- ncurses.initscr()
local path = 'test.txt'

local handle = inotify.init()
local wd = handle:addwatch(path, inotify.IN_MODIFY)
local fh = io.open(path, "r")

local line = fh:read()
local i = 0
while line do
  print(i .. " - " .. line)
  line = fh:read()
  i = i + 1
end

-- start watching the file for writes
local events, err, errno = handle:read()

-- print(events)
-- print(err)
-- print(errno)
if not events then
  print("an error occured: (" .. errno .. ") " .. err)
else
  for _, ev in ipairs(events) do
    print("the file was modified!")
    -- print(ev.name)
    -- print(ev.name .. ' was modified')
    line = fh:read()
    print("New entry: " .. line)
  end
end

fh:close()
handle:rmwatch(wd)
handle:close()

-- ncurses.endwin()
