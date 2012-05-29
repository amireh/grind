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

#ifndef H_GRIND_LOG_MANAGER_H
#define H_GRIND_LOG_MANAGER_H

#include "log.hpp"
#include "configurable.hpp"

#include <boost/filesystem.hpp>

namespace grind {

  typedef boost::filesystem::path path_t;

  /**
   * \addtogroup Core
   * @{
   * @class log_manager
   *
   * Manages a logging system through log4cpp that can be used by an application
   * to log messages to a number of output devices; stdout, a file, or syslog.
   *
   * Logging devices and the format of messages are configurable.
   *
   * Actual logging of the messages should be done by by instances derived from
   * grind::logger (see grind_logger.hpp).
   */
  class log_manager : public configurable {
  public:

    /* the log manager's config context is "log manager" */
    struct {
      string_t log_device;   /** possible values: 'stdout' or 'syslog' or 'file', default: 'file' */
      string_t log_level;    /** possible values: 'debug', 'notice', 'info', 'warn', 'error', default: 'debug' */

      /* the following apply only when logging to a file */
      string_t log_dir;      /** default: "log", the log file will be in /path/to/app/log/log_name.log */
      string_t log_name;     /** default: "grind.log" */
      string_t log_filesize; /** value format: "[NUMBER][B|K|M]", default: 10M */

      string_t app_name;
      string_t app_version;
      string_t app_website;

      bool     silent;
    } cfg;

    static log_manager& singleton();

    typedef log4cpp::Category log_t;

    /** The unique log4cpp::category identifier, used internally by logger instances */
    string_t const& category();

    virtual ~log_manager();
    log_manager(const log_manager&) = delete;
    log_manager& operator=(const log_manager&) = delete;

    /**
     * Initializes the logging system, this must be called before the log_manager
     * is configured.
     *
     * @param category_name
     *  A unique identifier for the primary logging category used to create
     *  instances of loggers. (Note: this string will not be visible in logs.)
     **/
    void init(string_t category_name = "grind");

    /**
     * If you init() the log manager, you must call this when you're done
     * to free allocated resources.
     *
     * @warning
     * Any attempt to log messages once the log manager is cleaned up might
     * result in undefined behaviour.
     */
    void cleanup();

    /**
     * Re-builds the logging system with the current configuration settings.
     *
     * @note
     * For internal implementation reasons, the log manager does not subscribe
     * itself to the "log manager" configuration context automatically; you must
     * do that somewhere BEFORE the configuration is parsed.
     *
     * IE, somewhere before you parse configuration file:
     *  configurator::subscribe(&log_manager::singleton(), "log manager");
     */
    virtual void configure();

    /** overridden from grind::configurable */
    virtual void set_option(string_t const& key, string_t const& value);

    /** a log that can be used by any entity that is not a derivative of grind::logger */
    log_t* log();

    static void silence();

  private:
    explicit log_manager();
    static log_manager* __instance;

    log4cpp::Appender *log_appender_;
    log4cpp::Layout   *log_layout_;
    log4cpp::Category *log_category_;
    log4cpp::Category *log_;
    log4cpp::Category *anonymous_log_;

    string_t category_name_;
    static bool silent_;
  };

# ifndef GRIND_LOG
#   define GRIND_LOG grind::log_manager::singleton().log()
# endif

  /** @} */

} // namespace grin

#endif // H_GRIND_LOG_MANAGER_H
