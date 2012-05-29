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

#include "log_manager.hpp"
#include "utility.hpp"
#include <map>

namespace grind {

  log_manager* log_manager::__instance = 0;
  bool log_manager::silent_ = false;

  void log_manager::silence() {
    silent_ = true;
  }

  log_manager::log_manager()
  : configurable(),
    log_appender_(0),
    log_layout_(0),
    log_category_(0),
    log_(0),
    anonymous_log_(0),
    category_name_("grind")
  {
    cfg.log_device = "stdout";
    cfg.log_dir = "log";
    cfg.log_name = "grind.log";
    cfg.log_level = "debug";
    cfg.log_filesize = "10M";
    cfg.app_name = "grind";
    cfg.app_version = "0.1.0";
    cfg.silent = false;

    init();
  }

  log_manager::~log_manager()
  {
  }

  log_manager& log_manager::singleton() {
    if (!__instance)
      __instance = new log_manager();

    return *__instance;
  }

  string_t const& log_manager::category() {
    return category_name_;
  }

  void log_manager::init(string_t cat) {
    category_name_ = cat;

    if (log_) // we already initialized
      return;

    log_category_ = &log4cpp::Category::getInstance(category_name_);
    log_category_->setAdditivity(false);
    log_category_->setPriority(log4cpp::Priority::DEBUG);

    log_
      = new log4cpp::FixedContextCategory(category_name_, "log_manager");
    anonymous_log_
      = new log4cpp::FixedContextCategory(category_name_, "anonymous");
  }

  void log_manager::cleanup()
  {
    if (log_)
      delete log_;
    if (anonymous_log_)
      delete anonymous_log_;

    // shutting down the log4cpp category will take care of freeing the
    // appenders and their layouts, so we don't have to deal with it
    log_appender_->close();
    log_category_->removeAppender(log_appender_);
    log_appender_ = 0;
    log_category_ = 0;
    log_layout_ = 0;
    log_ = anonymous_log_ = 0;

    log4cpp::Category::shutdown();
  }

  log_manager::log_t* log_manager::log()
  {
    return anonymous_log_;
  }

  void log_manager::configure()
  {
    // set the logging level
    std::map< string_t, log4cpp::Priority::Value > str2prio;
    str2prio.insert(std::make_pair("debug",  log4cpp::Priority::DEBUG));
    str2prio.insert(std::make_pair("notice", log4cpp::Priority::NOTICE));
    str2prio.insert(std::make_pair("info",   log4cpp::Priority::INFO));
    str2prio.insert(std::make_pair("warn",   log4cpp::Priority::WARN));
    str2prio.insert(std::make_pair("error",  log4cpp::Priority::ERROR));

    if (str2prio.find(cfg.log_level) == str2prio.end()) {
      std::cerr << "invalid logging level '" << cfg.log_level << "', falling back to DEBUG\n";

      cfg.log_level = "debug";
    }

    log_category_->setPriority(str2prio[cfg.log_level]);

    // remove the current appender
    if (log_appender_) {
      log_appender_->close();
      log_category_->removeAppender(log_appender_);
      log_appender_ = 0;
    }

    // create the new appender
    bool using_syslog = false;
    if (cfg.log_device == "syslog")
    {
      log_appender_ =	new log4cpp::SyslogAppender("SyslogAppender", "grind");
      using_syslog = true;
    }
    else if (cfg.log_device == "stdout")
    {
      assert(!log_appender_);
      log_appender_ =	new log4cpp::OstreamAppender("STDOUTAppender", &std::cout);
    }
    else
    {
      uint64_t filesz = 0;
      if (!utility::string_to_bytes(cfg.log_filesize, &filesz)) {
        std::cerr << "invalid log filesize '" << cfg.log_filesize << ", defaulting to 10M\n";
        filesz = 10 * 1024 * 1024;
      }

      // make sure the directory exists
      path_t log_path = path_t(cfg.log_dir);
      if (!boost::filesystem::exists(log_path))
        boost::filesystem::create_directory(log_path);

      log_appender_ =
      new log4cpp::RollingFileAppender(
        "RollingFileAppender",
        log_path.make_preferred().string() + "/" + cfg.log_name,
        filesz);
    }

    // register the appender
    log_category_->addAppender(log_appender_);

    // assign the real appender layout
    if (using_syslog)
      log_layout_ = new grind_syslog_log_layout();
    else
      log_layout_ = new grind_file_log_layout();

    log_appender_->setLayout(log_layout_);
    log_appender_->reopen();

    if (!silent_) {
      log_->getStream(str2prio[cfg.log_level]) << "logging level set to " << cfg.log_level;

      if (cfg.log_device == "file") {
        log_->getStream(str2prio[cfg.log_level])
        << "log file will be rotated every " << cfg.log_filesize;
      }
    }

  }

  void log_manager::set_option(string_t const& key, string_t const& value)
  {
    if (key == "log_device" || key == "log interface" || key == "log device" || key == "device")
    {
      if (value == "syslog")
        cfg.log_device = value;
      else if (value == "stdout")
        cfg.log_device = value;
      else if (value == "file")
        cfg.log_device = value;
      else {
        log_->warnStream() << "unknown logging mechanism specified '" << value << "', falling back to 'file'";
        cfg.log_device = "file";
      }
    }
    else if (key == "log_filesize" || key == "log filesize") {
      cfg.log_filesize = value;
    }
    else if (key == "log_name" || key == "log filename") {
      cfg.log_name = value;
    }
    else if (key == "log_dir" || key == "log directory") {
      cfg.log_dir = value;
    }
    else if (key == "log_level" || key == "log level") {
      cfg.log_level = value;
    }
    // else if (key == "app_name" || key == "app name") {
    //   cfg.app_name = value;
    // }
    // else if (key == "app_version" || key == "app version") {
    //   cfg.app_version = value;
    // }
    else if (key == "app_website" || key == "app website") {
      cfg.app_website = value;
    }
    else if (key == "log header") {
      cfg.silent = (value == "false") ? true : false;
    }
    else {
      log_->warnStream() << "unknown log_manager config setting '" << key << "' => '" << value << "', discarding";
    }
  }
} // namespace grind
