#include "script_engine.hpp"
#include "utility.hpp"
#include "kernel.hpp"

extern "C" {
  #include "dTE/swigluaruntime.h"

  struct swig_module_info;
  struct swig_type_info;
  swig_module_info *SWIG_Lua_GetModule(lua_State* L);
  swig_type_info *SWIG_TypeQueryModule(swig_module_info *start,swig_module_info *end,const char *name);
  void SWIG_Lua_NewPointerObj(lua_State* L,void* ptr,swig_type_info *type, int own);
}

namespace grind {

  script_engine::script_engine(kernel& kernel)
  : configurable({ "script_engine" }),
    logger("script_engine"),
    kernel_(kernel),
    lua_(nullptr),
    stopping_(false)
  {
    config.error_handling = CATCH_AND_DIE;
    config.error_handling = CATCH_AND_THROW;
  }

  script_engine::~script_engine() {
  }

  void script_engine::start() {
    if (lua_)
      return;

    log_->infoStream() << "grind Lua engine is starting...";

    lua_ = lua_open();
    luaL_openlibs(lua_);
    log_->infoStream() << "scripts path set to: " << config.scripts_path;
    string_t entry_script = (path_t(config.scripts_path) / "grind.lua").string();

    int rc = luaL_dofile(lua_, entry_script.c_str());
    if (rc == 1) {
      return handle_error();
    }
    lua_remove(lua_, lua_gettop(lua_));

    lua_getglobal(lua_, "set_paths");
    if(!lua_isfunction(lua_, -1))
    {
      log_->errorStream() << "could not find Lua path initter! Corrupt state?";
      return handle_error();
    }

    lua_pushfstring(lua_, config.scripts_path.c_str());
    int ec = lua_pcall(lua_, 1, 0, 0);
    if (ec != 0)
    {
      // there was a lua error, dump the state and shut down the instance
      return handle_error();
    }

    pass_to_lua("grind.start", 0);

    log_->infoStream() << "grind Lua engine has started.";
  }

  void script_engine::restart() {
    if (!lua_)
      return;

    log_->infoStream() << "restarting the Lua state...";
    // pass_to_lua("script_engine.restart", 0);
    stop();
    start();

    log_->infoStream() << "Lua state has been restarted.";
  }

  void script_engine::stop(bool valid_state) {
    if (!lua_ || stopping_) {
      return;
    }

    stopping_ = true;

    log_->infoStream() << "grind Lua is stopping...";

    if (valid_state)
      pass_to_lua("grind.stop", 0);


    lua_close(lua_);
    lua_ = nullptr;

    log_->infoStream() << "grind Lua is off.";

    stopping_ = false;
  }

  void script_engine::handle_error() {
    const char* error_c = lua_tostring(lua_, -1);
    string_t error;
    if (error_c) {
      // string_t error = lua_tostring(lua_, -1);
      error = string_t(error_c);
      log_->errorStream() << "Lua error: " << error;
      lua_pop(lua_, -1);
    }

    stop(false);

    switch(config.error_handling) {
      case CATCH_AND_THROW:
        throw std::runtime_error("Lua error: " + error);
        break;
      case CATCH_AND_DIE:
        assert(false);
        break;
      default:
        assert(false);
    }
  }

  void script_engine::set_option(const string_t &k, const string_t& v) {
    if (k == "error handling") {
      if (v == "exception")
        config.error_handling = script_engine::CATCH_AND_THROW;
      else
        config.error_handling = script_engine::CATCH_AND_DIE;
    }
    else if (k == "scripts path") {
      config.scripts_path = v;
    }
  }

  void script_engine::push_userdata(void* data, string_t type)
  {
    SWIG_Lua_NewPointerObj(
      lua_,
      data,
      SWIG_TypeQueryModule(
        SWIG_Lua_GetModule(lua_),
        SWIG_Lua_GetModule(lua_),
        (type + " *").c_str()),0);
  }
  bool script_engine::pass_to_lua(const char* in_func, std::function<void()> arg_extractor, int argc, ...) {
    scoped_lock lock(mtx_);

    va_list argp;

    lua_getfield(lua_, LUA_GLOBALSINDEX, "arbitrator");
    if(!lua_isfunction(lua_, -1))
    {
      log_->errorStream() << "could not find Lua arbitrator functor!";
      handle_error();
      return false;
    }

    lua_pushfstring(lua_, in_func);

    va_start(argp, argc);
    for (int i=0; i < argc; ++i) {
      const char* argtype = (const char*)va_arg(argp, const char*);
      void* argv = (void*)va_arg(argp, void*);
      if (string_t(argtype) == "std::string")
        lua_pushfstring(lua_, ((string_t*)argv)->c_str());
      else
        push_userdata(argv, argtype);
    }
    va_end(argp);

    int ec = lua_pcall(lua_, argc+1, 1, 0);
    if (ec != 0)
    {
      // there was a lua error, dump the state and shut down the instance
      handle_error();
      return false;
    }

    if (arg_extractor)
      arg_extractor();

    return true;
  }

  void script_engine::relay(string_t const& buf) {

    // string_t result;
    pass_to_lua("grind.handle",
                nullptr,
                // [&]() -> void {
                //   result = lua_tostring(lua_, lua_gettop(lua_));
                //   lua_remove(lua_, lua_gettop(lua_));
                // },
                1,
                "std::string", &buf);

    // std::cout << "Result: \n" << result << '\n';
    // if (result != "[]") {
    //   kernel_.broadcast(result);
    // }

  }

  script_engine::cmd_rc_t script_engine::handle_cmd(string_t const& buf, void* watcher) {
    cmd_rc_t rc;
    rc.success = false;

    string_t result;
    pass_to_lua("grind.handle_cmd",
                [&]() -> void {
                  result = lua_tostring(lua_, lua_gettop(lua_));
                  lua_remove(lua_, lua_gettop(lua_));
                },
                2,
                "std::string", &buf,
                "grind::connection", watcher);

    // std::cout << "Result: \n" << result << '\n';

    if (result != "nil") {
      rc.success = true;
      rc.result = result;
    }

    return rc;
  }

}
