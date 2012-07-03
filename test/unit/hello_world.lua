#!/usr/bin/env lua

package.cpath = "/usr/local/lib/?.so;" .. package.cpath
local ncurses = require "lua_ncurses"

local printw = ncurses.printw

ncurses.initscr()
ncurses.cbreak()
ncurses.keypad(ncurses.stdscr, true)
ncurses.noecho()

printw("Type something\n")
ch = ncurses.getch()
if ch == ncurses.KEY_F1 then
  printw("F1 Key pressed")
else
  printw("The pressed key is ")
  ncurses.attron(ncurses.A_BOLD)
  printw(ch)
  ncurses.attroff(ncurses.A_BOLD)
end

ncurses.refresh()

ncurses.getch()
ncurses.endwin()
