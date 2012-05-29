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

#ifndef H_GRIND_LOG4CPP_SYSLOG_LOG_LAYOUT_H
#define H_GRIND_LOG4CPP_SYSLOG_LOG_LAYOUT_H

#include <log4cpp/Portability.hh>
#include <log4cpp/Layout.hh>
#include <memory>

using namespace log4cpp;
namespace grind {

  /** A log4cpp layout that writes to Syslog. */
  class LOG4CPP_EXPORT grind_syslog_log_layout : public Layout {
    public:
    grind_syslog_log_layout();
    virtual ~grind_syslog_log_layout();

    /**
     * Formats the LoggingEvent in PixyLogLayout style:<br>
     * "timeStamp priority category ndc: message"
     **/
    virtual std::string format(const LoggingEvent& event);

    protected:
  };
}

#endif // END OF H_GRIND_LOG4CPP_LOG_LAYOUT_H
