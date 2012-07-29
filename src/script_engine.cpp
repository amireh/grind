#include "script_engine.hpp"
#include "utility.hpp"
#include "kernel.hpp"

extern "C" {
  #include "swigluaruntime.h"

  struct swig_module_info;
  struct swig_type_info;
  swig_module_info *SWIG_Lua_GetModule(lua_State* L);
  swig_type_info *SWIG_TypeQueryModule(swig_module_info *start,swig_module_info *end,const char *name);
  void SWIG_Lua_NewPointerObj(lua_State* L,void* ptr,swig_type_info *type, int own);
}

namespace grind {

  script_engine::script_engine(kernel& kernel)
  : logger("script_engine"),
    kernel_(kernel),
    lua_(NULL),
    stopping_(false),
    running_(false)
  {
    config.error_handling = CATCH_AND_DIE;
    config.error_handling = CATCH_AND_THROW;
  }

  script_engine::~script_engine() {
  }

  static int stack_trace_printer(lua_State *L) {
    lua_getfield(L, LUA_GLOBALSINDEX, "debug");
    if (!lua_istable(L, -1)) {
      lua_pop(L, 1);
      return 1;
    }
    lua_getfield(L, -1, "traceback");
    if (!lua_isfunction(L, -1)) {
      lua_pop(L, 2);
      return 1;
    }
    lua_pushvalue(L, 1);
    lua_pushinteger(L, 2);
    lua_call(L, 2, 1);
    return 1;
  }

  typedef std::vector<string_t> directories_t;

  static path_t locate_file(directories_t directories, string_t filename) {
    using boost::filesystem::is_directory;

    for ( directories_t::const_iterator ditr = directories.begin(); ditr != directories.end(); ++ditr) {
      string_t const& d_str = *ditr;
      path_t d(d_str);

      if (!is_directory(d))
        continue;

      path_t file = d / "config.lua";

      if (exists(file))
        return file;
      
    }
    return path_t();
  }
  
  static path_t locate_config() {
    directories_t paths;
    paths.push_back("/etc/grind");
    paths.push_back("/usr/share/grind");
    paths.push_back("/usr/local/share/grind");

    return locate_file(paths, "config.lua");
  }

  void script_engine::start(string_t const& in_cfg_path) {
    if (lua_)
      return;

    if (in_cfg_path.empty()) {
      cfg_path_ = locate_config();
      if (cfg_path_.empty()) {
        throw std::runtime_error("Unable to locate grind configuration file!");
      }
    } else {
      cfg_path_ = path_t(in_cfg_path);
      if (!exists(cfg_path_))
        throw std::runtime_error("Specified configuration file is invalid: " + in_cfg_path);
      else if(is_directory(cfg_path_))
        throw std::runtime_error("Please specify a grind configuration file, not a directory: " + in_cfg_path);
    }

    // configure
    info() << "configuring from: " << cfg_path_.string() << '\n';

    lua_ = lua_open();
    luaL_openlibs(lua_);
    int rc = luaL_dofile(lua_, cfg_path_.string().c_str());
    if (rc == 1) {
      return handle_error();
    }

    info() << "Lua stack[initial] size is: " << lua_gettop(lua_) << '\n';

    // lua_getglobal(lua_, "set_paths");
    // if(!lua_isfunction(lua_, -1))
    // {
    //   error() << "could not find Lua path initter! Corrupt state?";
    //   return handle_error();
    // }

    // lua_pushfstring(lua_, config.scripts_path.c_str());
    // int ec = lua_pcall(lua_, 1, 0, 0);
    // if (ec != 0)
    // {
    //   // there was a lua error, dump the state and shut down the instance
    //   return handle_error();
    // }

    running_ = true;

    pass_to_lua("grind.start", boost::bind(&script_engine::on_grind_start, this), 1, 1, "grind::kernel", &kernel_);

    if (!running_)
      return;

    info() << "grind Lua engine has started.\n";
  }

  void script_engine::on_grind_start() {
    running_ = lua_toboolean(lua_, -1);
    lua_pop(lua_, 1);
  }

  void script_engine::restart() {
    if (!lua_)
      return;

    info() << "restarting the Lua state...\n";
    // pass_to_lua("script_engine.restart", 0);
    stop();
    start(cfg_path_.string());

    info() << "Lua state has been restarted.\n";
  }

  void script_engine::stop(bool valid_state) {
    if (!lua_ || stopping_) {
      return;
    }

    stopping_ = true;

    info() << "grind Lua is stopping...\n";
    info() << "Lua stack has " << lua_gettop(lua_) << " elements\n";

    if (valid_state)
      pass_to_lua("grind.stop");

    lua_close(lua_);
    lua_ = NULL;

    info() << "grind Lua is off.\n";

    stopping_ = false;
  }

  void script_engine::handle_error() {
    // Stk: Func(C.stp) String(error_msg)
    info() << "Lua stack[error] has " << lua_gettop(lua_) << " elements.\n";

    const char* error_c = lua_tostring(lua_, -1);
    string_t error;
    if (error_c) {
      error = string_t(error_c);
      logger::error() << "Lua error: " << error << '\n';
      lua_pop(lua_, 1); // Stk: Func(C.stp)
    }

    lua_pop(lua_, 1); // Stk: 

    running_ = false;

    stop(false);

    switch(config.error_handling) {
      case CATCH_AND_THROW:
        throw std::runtime_error("Lua error: " + error);
        break;
      case CATCH_AND_DIE:
        if (kernel_.is_running())
          kernel_.stop();
        break;
      default:
        assert(false);
    }
  }

  bool script_engine::is_running() { return running_; }

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

  bool script_engine::pass_to_lua(const char* in_func, boost::function<void()> ret_extractor, int retc, int argc, ...) {
    scoped_lock lock(mtx_);

    va_list argp;

    int initial_size = lua_gettop(lua_);
    #ifdef DEBUG
    info() << "Lua stack[pre_pass] has " << lua_gettop(lua_) << " elements.\n";
    #endif

    lua_pushcfunction(lua_, stack_trace_printer);
    int error_index = lua_gettop(lua_);

    // Stk: Func(C.stp) Func(lua.arb)
    lua_getfield(lua_, LUA_GLOBALSINDEX, "arbitrator");
    if(!lua_isfunction(lua_, -1))
    {
      error() << "could not find Lua arbitrator functor!\n";
      handle_error();
      return false;
    }

    lua_pushfstring(lua_, in_func); // Stk: Func(C.stp) Func(lua.arb) String
    
    va_start(argp, argc);
    for (int i=0; i < argc; ++i) {
      const char* argtype = (const char*)va_arg(argp, const char*);
      void* argv = (void*)va_arg(argp, void*);
      if (string_t(argtype) == "std::string")
        lua_pushfstring(lua_, ((string_t*)argv)->c_str());
      else
        push_userdata(argv, argtype);

      // Stk: Func(C.stp) Func(lua.arb) String userdata[0]...userdata[i]
    }
    va_end(argp);

    // Stk: Func(C.stp) Func(lua.arb) String userdata[0]...userdata[argc]
    #ifdef DEBUG
    info() << "Lua stack[pre_invoke] has " << lua_gettop(lua_) << " elements.\n";
    #endif

    int ec = lua_pcall(lua_, argc+1, retc, error_index);
    if (ec != 0)
    {
      handle_error();
      return false;
    }
    // info() << "Lua stack[post_invoke] has " << lua_gettop(lua_) << " elements.";

    if (ret_extractor) {
      // the extractor is responsible for cleaning up the stack
      ret_extractor();
    } else {
      // clean up the stack ourselves
      for (int i = 0; i < retc; ++i) {
        lua_pop(lua_, 1);
        // Stk: Func(C.stp) ret[0]...ret[retc-i]
      }
    }

    // Stk: Func(C.stp)      
    lua_pop(lua_, 1);
    // Stk:    

    #ifdef DEBUG
    info() << "Lua stack[post_pass] has " << lua_gettop(lua_) << " elements.\n";
    #endif

    assert(lua_gettop(lua_) == initial_size);
    return true;
  }

  void script_engine::relay(string_t const& buf, feeder* f) {

    // string_t result;
    pass_to_lua("grind.handle",
                NULL,
                0,
                // [&]() -> void {
                //   result = lua_tostring(lua_, lua_gettop(lua_));
                //   lua_remove(lua_, lua_gettop(lua_));
                // },
                2,
                "std::string", &buf,
                "std::string", &f->label());

    // std::cout << "Result: \n" << result << '\n';
    // if (result != "[]") {
    //   kernel_.broadcast(result);
    // }

  }

  void script_engine::handle_cmd(string_t const& buf, void* watcher) {
    // cmd_rc_t rc;
    // rc.success = false;

    // string_t result;
    pass_to_lua("grind.handle_cmd",
                NULL,
                0,
                // [&]() -> void {
                //   result = lua_tostring(lua_, lua_gettop(lua_));
                //   lua_remove(lua_, lua_gettop(lua_));
                // },
                2,
                "std::string", &buf,
                "grind::connection", watcher);

    // std::cout << "Result: \n" << result << '\n';

    // if (result != "nil") {
    //   rc.success = true;
    //   rc.result = result;
    // }

    // return rc;
  }

}
