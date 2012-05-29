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

#ifndef H_GRIND_EXCEPTION_H
#define H_GRIND_EXCEPTION_H

#include <exception>
#include <string>
#include <stdexcept>

namespace grind {

  /* bad conversion
   *
   * thrown when an argument passed to utility::convertTo<> is not a number
   * and thus can not be converted
   **/
  class bad_conversion : public std::runtime_error {
  public:
    inline bad_conversion(const std::string& s)
    : std::runtime_error(s)
    { }
  };

  /* thrown when a messaging channel cannot be opened (connection to messaging daemon can't be established) */
	class connection_error : public std::runtime_error {
	public:
		inline connection_error(const std::string& s)
		: std::runtime_error(s)
		{ }
	};

} // namespace grind

#endif
