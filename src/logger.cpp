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

#include "logger.hpp"
#include <iomanip>

namespace grind {

  static char levels[] = { 'D','I','N','W','E','A','C' };
  static char threshold = 'D';

  ostringstream logger::sink;

  void logger::set_threshold(char level) {
    threshold = level;
  }

  logger::logger(string_t context)
  : context_(context)
  {
  }

  logger::~logger()
  {
  }

  ostream& logger::log(char lvl) {
    bool enabled = false;
    for (int i = 0; i < 7; ++i)
      if (levels[i] == threshold) { enabled = true; break; }
      else if (levels[i] == lvl) break;

    if (!enabled)
      return sink;

    struct tm *pTime;
    time_t ctTime; time(&ctTime);
    pTime = localtime( &ctTime );
    std::ostringstream timestamp;
    timestamp
      << std::setw(2) << std::setfill('0') << pTime->tm_mon
      << '-' << std::setw(2) << std::setfill('0') << pTime->tm_mday
      << '-' << std::setw(4) << std::setfill('0') << pTime->tm_year + 1900
      << ' ' << std::setw(2) << std::setfill('0') << pTime->tm_hour
      << ":" << std::setw(2) << std::setfill('0') << pTime->tm_min
      << ":" << std::setw(2) << std::setfill('0') << pTime->tm_sec
      << " ";

    std::cout << timestamp.str() << "[" << lvl << "]" << " " << context_ << ": ";
    return std::cout;
  }

  ostream& logger::debug()  { return log('D'); }
  ostream& logger::info()   { return log('I'); }
  ostream& logger::notice() { return log('N'); }
  ostream& logger::warn()   { return log('W'); }
  ostream& logger::error()  { return log('E'); }
  ostream& logger::alert()  { return log('A'); }
  ostream& logger::crit()   { return log('C'); }
}
