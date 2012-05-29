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

#ifndef H_GRIND_MESSAGE_H
#define H_GRIND_MESSAGE_H

#include "grind.hpp"

#include <vector>
#include <exception>
#include <map>
#include <iostream>
#include <boost/crc.hpp>
#include <boost/asio.hpp>

namespace grind {

  typedef string_t message_uid;

  enum class message_feedback : unsigned char {
    unassigned = 0,

    ok,
    error,
    invalid_request,
    invalid_credentials,

    sanity_check
  };

  /**
   * \addtogroup Core
   * @{
   *  @class message
   *    Message object that is used and handled to represent commands sent
   *    by the dakapi shell.
   */
  struct message {

    enum {
      // if length is small enough it will be cast to 1 byte thus we can't
      // depend on uint16_t being interpreted as 2 bytes long.. so we -1
      header_length = 7, // "uidoptionsfeedbacklength"
      footer_length = 4 // "\r\n\r\n"
    };

    // event options
    enum {
      no_format    = 0x01 // events with no format will not be parsed per-property
    };

		typedef	std::map< string_t, string_t > property_t;

    message();
    message(const message_uid inuid,
            const message_feedback = message_feedback::unassigned,
            unsigned char options = 0);
    message(const message& src);
    message& operator=(const message& rhs);

		~message();

    bool from_stream(boost::asio::streambuf& in);
    void to_stream(boost::asio::streambuf& out) const;

    /** resets event state */
    void reset();

		string_t const& property(string_t inName) const;

		void set_property(const string_t inName, const string_t inValue);
    void set_property(const string_t inName, int inValue);
    bool has_property(const string_t inName) const;
    bool has_option(unsigned char message_option) const;

    friend std::ostream& operator<<(std::ostream&, const message&);
    std::string const& operator[](std::string const& property) const;

    /// debug
		void dump(std::ostream& inStream = std::cout) const;

		message_uid		        uid;
    uint32_t              uid_length;
    unsigned char         options;
    message_feedback      feedback;
    uint32_t              length;
		int                   checksum;
    property_t		        properties;
    uint32_t              rawsz;
    static const char     *footer;
    static const uint32_t max_length; // no single message can be longer than this (2^32-1)
    void                  *any;

    static const string_t null_property_;

    static int _CRC32(const string_t& my_string);
    static string_t _uid_to_string(message_uid);
		void _clone(const message& src);
	};
  /** @} */

} // namespace grind

#endif
