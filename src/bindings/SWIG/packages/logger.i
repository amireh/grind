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

%module lua_grind
%{
  #include "logger.hpp"
  #include <log4cpp/Category.hh>
  #include <log4cpp/Portability.hh>
  #include <log4cpp/Appender.hh>
  #include <log4cpp/LoggingEvent.hh>
  #include <log4cpp/Priority.hh>
  #include <log4cpp/CategoryStream.hh>
  #include <log4cpp/threading/Threading.hh>
  #include <log4cpp/convenience.h>
%}

namespace log4cpp {

  /**
   * This is the central class in the log4j package. One of the distintive
   * features of log4j (and hence log4cpp) are hierarchal categories and
   * their evaluation.
   **/
  class Category {
  private:
    Category();

  public:
    virtual ~Category();
    /**
     * Log a message with debug priority.
     * @param stringFormat Format specifier for the string to write
     * in the log file.
     * @param ... The arguments for stringFormat
     **/
    // void debug(const char* stringFormat, ...) throw();

    /**
     * Log a message with debug priority.
     * @param message string to write in the log file
     **/
    void debug(const std::string& message) throw();


    /**
     * Log a message with info priority.
     * @param message string to write in the log file
     **/
    void info(const std::string& message);


    /**
     * Log a message with notice priority.
     * @param message string to write in the log file
     **/
    void notice(const std::string& message) throw();


    /**
     * Log a message with warn priority.
     * @param message string to write in the log file
     **/
    void warn(const std::string& message) throw();


    /**
     * Log a message with error priority.
     * @param message string to write in the log file
     **/
    void error(const std::string& message) throw();


    /**
     * Log a message with crit priority.
     * @param message string to write in the log file
     **/
    void crit(const std::string& message) throw();


    /**
     * Log a message with alert priority.
     * @param message string to write in the log file
     **/
    void alert(const std::string& message) throw();

    /**
     * Log a message with emerg priority.
     * @param message string to write in the log file
     **/
    void emerg(const std::string& message) throw();

    /**
     * Log a message with fatal priority.
     * NB. priority 'fatal' is equivalent to 'emerg'.
     * @since 0.2.7
     * @param message string to write in the log file
     **/
    void fatal(const std::string& message) throw();
  };

}

namespace grind {

  /**
   * \addtogroup Core
   * @{
   * @class logger
   * Logger instances can log messages using the grind::log_manager system.
   */
  class logger
  {
  public:

    /**
     * @param context
     *  A prefix prepended to every message logged by this system. This should
     *  normally denote the name of the logging module.
     */
    explicit logger(string_t context);
    virtual ~logger();

    log4cpp::Category* log();
  }; // end of logger class

  /** @} */

} // end of namespace grind
