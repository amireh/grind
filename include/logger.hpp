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

#ifndef H_GRIND_LOGGER_H
#define H_GRIND_LOGGER_H

#include "grind.hpp"
#include "log.hpp"
#include "log_manager.hpp"

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
		explicit logger(const char* context);
    explicit logger(string_t context);
		logger(const logger& src);
		virtual ~logger();
    logger& operator=(const logger& rhs);

    log4cpp::Category* log();

    log4cpp::CategoryStream debug();
    log4cpp::CategoryStream info();
    log4cpp::CategoryStream notice();
    log4cpp::CategoryStream warn();
    log4cpp::CategoryStream error();
    log4cpp::CategoryStream alert();
    log4cpp::CategoryStream crit();

	protected:
		log4cpp::Category* log_;

    void __create_logger(const char* context);
    void __destroy_logger();

  private:
    string_t context_;
	}; // end of logger class

  /** @} */

} // end of namespace grind

#endif
