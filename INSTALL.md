To set up grind, you should begin by building the core, then getting a
Watcher set up, and optionally a Keeper.

## The grind core

The core is composed of C++ source files and Lua scripts. CMake is 
used for building the source.

> As of this writing there are no packaged builds and you will have to
 do this manually.

**C++ dependencies:**

Make sure you got [CMake](www.cmake.org) installed. Afterwards, you 
need to get the following development libraries set up:

* [gcc 4.6.2+](http://gcc.gnu.org/) or any fully C++0x-compliant compiler
* [boost](http://www.boost.org) 1.46 or higher *(the used parts of 
  boost are: filesystem, thread, date_time, system, and regex)*
* [log4cpp](http://log4cpp.sourceforge.net)
* [Lua](http://www.lua.org/) development headers

> **Note**: for the remainder of this article, the 
> directory which contains the grind repository will
> be referred to as $GRIND.

### Building the C++ core

Fire up a terminal and go to `$GRIND`, and create a directory called 
`build` which will contain CMake's temporary build files:

```bash
cd $GRIND; mkdir build && cd build;
ccmake ..
```

Now you are faced with the ncurses CMake interface. Type `c` to 
configure the package (look for the dependencies). If the configuration
fails, make sure you haven't missed any of the dependencies above. 
When configured, type `g` to generate the build script and ccmake will now exit.

```bash
make && sudo make install
```

Will build the grind C++ core, and the Lua bindings which will be 
installed to `/usr/local/lib` (or whatever `INSTALL_PREFIX` you've chosen). 
A configuration script will also be installed to `/etc/grind/config.lua`, 
we will get to that later.

> **About the bindings**
>
> While the Lua bindings wrapper is already generated for you,
> if you want to generate it yourself you need [SWIG](http://www.swig.org)
> and a Python interpreter (2 or 3, doesn't matter.)
>
> Once that is done, go to the build directory and type `make -B lua_grind_SWIG`.

### Preparing the Lua core

Make sure you have [Lua 5.1](http://www.lua.org/) installed, as well 
as the [luarocks](http://luarocks.org) package manager. When luarocks 
is set up, you can use it to install the Lua dependencies:

* lrexlib-pcre
* lua-cjson
* luafilesystem
* lua_cliargs
* luasocket - optional, needed for some tests and helper tools

> **For Debian and Ubuntu users**
>
> I've had to do `ldconfig` after `make install` for
> Lua to find the bindings, you might have to do so as well.

***

Now you should have grind set up, but it still needs 
[configuring](https://github.com/amireh/grind/wiki/Configuring-grind).
You should probably configure the grind core before setting up a Watcher.

Running grind is as simple as:

```bash
grind
```

## Watchers

Watchers are the interface for grind. A watcher allows you to connect 
to a grind instance and display entries that you're interested in.

### The Ruby HTML5 watcher

This is a web UI. It uses [EventMachine](http://rubyeventmachine.com/)
with HTML5 WebSockets for communication between the JavaScript and 
the grind instance. It also uses [Sinatra](http://sinatrarb.com) for 
the actual web application. Stylesheets are written using 
[SASS](http://sass-lang.com/), and [jQuery](http://jquery.com/) is also used.

You will need Ruby 1.9.2+ and the following gems:

* sinatra
* sinatra-content-for
* sass
* json
* yajl
* eventmachine
* em-websocket

You also need a websocket-enabled browser.

Running the Watcher is done in two steps. First, run the internal 
Watcher server:

```bash
cd grind/watchers/ruby
ruby server.rb
```

And then the web server:

```bash
cd grind/watchers/ruby
ruby app.rb
```

**Running the Watcher under PhusionPassenger and httpd**

Simply define a virtual host entry in your Apache httpd config file 
that contains something like this:

```
<VirtualHost *:80>
   ServerName grind.mydomain.com
   DocumentRoot /path/to/grind/watchers/ruby/public
   PassengerAppRoot /path/to/grind/watchers/ruby
   <Directory /path/to/grind/watchers/ruby/public>
      AllowOverride all
      Options -MultiViews
   </Directory>
</VirtualHost>
```

Note that you still have to make sure `server.rb` is running.

=======

Grats! With the core and a Watcher set up, you are now ready to use grind. 
The next step is optional, you only need to do it if you want to archive 
the data (which you should, really.)

## Keepers

Keepers store and archive the entries produced by grind in a database 
for offline viewing, querying, or even stat aggregation. Right now 
there's only one Keeper implemented that uses MongoDB and is written 
in Ruby.

### The MongoDB Ruby Keeper

Just as with the Ruby Watcher above, you will need Ruby 1.9.2+ with 
the following gems:

* json
* yajl
* mongo
* eventmachine
* sinatra

The Keeper, by default, connects to MongoDB in Single mode and writes 
to a database called grind. The Keeper's web API is accessible via the 
port **11146**. For more info about Keepers, see 
[this article](https://github.com/amireh/grind/wiki/Keepers)

Running the Keeper is done by:

```bash
cd grind/keepers/mongo && ruby keeper.rb
```