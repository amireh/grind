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

#include "log4cpp/syslog_log_layout.hpp"
#include <log4cpp/Priority.hh>
#ifdef LOG4CPP_HAVE_SSTREAM
#include <sstream>
#endif
#include <iostream>

namespace grind {

  grind_syslog_log_layout::grind_syslog_log_layout() {
  }

  grind_syslog_log_layout::~grind_syslog_log_layout() {
  }

  std::string grind_syslog_log_layout::format(const LoggingEvent& event) {

		std::ostringstream message;

    const std::string& priorityName = Priority::getPriorityName(event.priority);

		// start off with priority
		message << "[" << priorityName[0]	<< "] ";

		// append NDC
		if (event.ndc != "")
			message << event.ndc << ": ";

		message << event.message << "\n";

    return message.str();
  }

}
