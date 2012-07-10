/*
 *  Copyright (c) 2011-2012 Ahmad Amireh <kandie@mxvt.net>
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a
 *  copy of this software and associated documentation files (the "Software"),
 *  to deal in the Software without restriction, including without limitation
 *  the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *  and/or sell copies of the Software, and to permit persons to whom the
 *  Software is furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 *  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 *
 */

#ifndef H_SCRIPT_ENGINE_H
#define H_SCRIPT_ENGINE_H

#include <lua.hpp>

#include "logger.hpp"
#include "configurable.hpp"
#include <boost/thread.hpp>
#include <boost/filesystem.hpp>
#include <boost/interprocess/sync/interprocess_mutex.hpp>

namespace grind {

  typedef boost::filesystem::path path_t;
  class kernel;
  class script_engine : public configurable, public logger {
  public:
    script_engine(kernel&);
    virtual ~script_engine();

    struct {
      char      error_handling;
      string_t  scripts_path;
    } config;

    /** Builds the Lua state and starts Lua script_engine. */
    void start();

    void restart();

    void relay(string_t const& buffer);

    // struct cmd_rc_t {
    //   bool      success;
    //   string_t  result;
    // };

    void handle_cmd(string_t const&, void* watcher);

    /** Destroys the Lua state, turning off the Lua engine. */
    void stop(bool valid_state = true);

    virtual void set_option(const string_t&, const string_t&);
    bool pass_to_lua(const char* inFunc, std::function<void()> = nullptr, int argc = 0, ...);
  private:
    void push_userdata(void* data, string_t type);
    void handle_error();

    lua_State  *lua_;
    int         id_;
    bool        stopping_;
    kernel      &kernel_;

    boost::interprocess::interprocess_mutex mtx_;

    enum {
      CATCH_AND_DIE,
      CATCH_AND_THROW
    };
  };
}

#endif
