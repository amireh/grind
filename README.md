# grind

grind is a tool that helps you extract information stored in your application 
log files, and gives you the ability to reformat that data or view a subset of
it at any time.

Log files could get messy, and when your software matures and gets deployed on
production servers it becomes a daunting task to find out what's going on. Even
if there's only a single rotating log file, grind saves your time by making it
easy to reach any kind information you're after.

# Features

* View and analyze logs from different applications across multiple servers from a single, unified interface
* Utmost flexibility thanks to grind being completely [PCRE](http://www.pcre.org)-driven
* Easy to configure; grind uses [Lua](http://www.lua.org), internally and for configuration, with super-clean syntax
* Archiving of formatted data for offline querying or history backtracking
* Bandwidth-efficient; nothing is transmitted except for what you're currently viewing
* Filtering system that allows you to control exactly what you want to receive at any time
* Horizontal and vertical parsing; pieces of data can be extracted not only from a single message, but from several ones too
* Completely free and open source!
* Ready examples for popular applications like Apache httpd, Ruby on Rails, Ogre3D, and CEGUI

# Getting started

First you need to get grind [installed](https://github.com/amireh/grind/wiki/Installing-grind)
and [configured](https://github.com/amireh/grind/wiki/Configuring-grind). After that, you should
take a look at its [structure](https://github.com/amireh/grind/wiki/Grind-overview) to get briefed
on some terminology and how things work. Afterwards, go through the
[tutorials](https://github.com/amireh/grind/wiki/Tutorial-1:-Birth-of-the-chimp) for a good look at
using grind's features, or if you're really impatient, check out the
[5-minute](https://github.com/amireh/grind/wiki/The-5-minute-crash-course) tutorial.

# License

The MIT License - Copyright (c) 2011-2012 Ahmad Amireh