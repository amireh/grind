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

#ifndef H_GRIND_UTILITY_H
#define H_GRIND_UTILITY_H

#include <typeinfo>
#include <sstream>
#include <vector>
#include <iostream>
#include <string>
#include <algorithm>
#include <malloc.h>
#include <iomanip>

namespace grind {
namespace utility {

  typedef std::string string_t;

  inline static string_t stringify(bool x)
  {
    return x ? "true" : "false";
  }

	template<typename T>
	inline static string_t stringify(const T& x)
	{
		std::ostringstream o;
		if (!(o << x))
			throw bad_conversion(string_t("stringify(")
								+ typeid(x).name() + ")");
		return o.str();
	}

	// helper; converts an integer-based type to a string
	template<typename T>
	inline static void convert(const string_t& inString, T& inValue,
						bool failIfLeftoverChars = true)
	{
		std::istringstream _buffer(inString);
		char c;
		if (!(_buffer >> inValue) || (failIfLeftoverChars && _buffer.get(c)))
			throw bad_conversion(inString);
	}

	template<typename T>
	inline static T convertTo(const string_t& inString,
					   bool failIfLeftoverChars = true)
	{
		T _value;
		convert(inString, _value, failIfLeftoverChars);
		return _value;
	}

  /* splits a string s using the delimiter delim */
  // inline static
  // std::vector<string_t> split(const string_t &s, char delim) {
  //   std::vector<string_t> elems;
  //   std::stringstream ss(s);
  //   string_t item;
  //   while(std::getline(ss, item, delim)) {
  //       elems.push_back(item);
  //   }
  //   return elems;
  // }

  // inline static
  // void ijoin(const std::vector<string_t>& tokens, string_t &out, char delim) {
  //   for (std::vector<string_t>::const_iterator token = tokens.begin();
  //   token != tokens.end();
  //   ++token)
  //   {
  //     out += *token;
  //     out.push_back(delim);
  //   }
  // }

  // inline static
  // string_t join(const std::vector<string_t>& tokens, char delim) {
  //   string_t out;
  //   ijoin(tokens, out, delim);
  //   return out;
  // }

  // inline static
  // void trimi(string_t &s) {
  //   int ws_ctr = 0;
  //   for (string_t::const_iterator sitr = s.begin(); sitr != s.end(); ++sitr)
  //   {
  //     char c = *sitr;
  //     if (c == ' ' || c == '\t')
  //       ++ws_ctr;
  //     else
  //       break;
  //   }

  //   int reverse_ws_ctr = 0;
  //   char c;
  //   for (int i=s.size()-1; i >= 0; --i)
  //   {
  //     c = s[i];
  //     if (c == ' ' || c == '\t')
  //       ++reverse_ws_ctr;
  //     else
  //       break;
  //   }

  //   if (ws_ctr > 0 || reverse_ws_ctr > 0)
  //     s = s.substr(ws_ctr, s.size() - (ws_ctr + reverse_ws_ctr));
  // }

  // inline static
  // void full_trimi(string_t &s) {
  //   int ws_ctr = 0;
  //   for (string_t::const_iterator sitr = s.begin(); sitr != s.end(); ++sitr)
  //   {
  //     char c = *sitr;
  //     if (c == ' ' || c == '\t' || c == '\n' || c == '\r')
  //       ++ws_ctr;
  //     else
  //       break;
  //   }

  //   int reverse_ws_ctr = 0;
  //   char c;
  //   for (int i=s.size()-1; i >= 0; --i)
  //   {
  //     c = s[i];
  //     if (c == ' ' || c == '\t' || c == '\n' || c == '\r')
  //       ++reverse_ws_ctr;
  //     else
  //       break;
  //   }

  //   if (ws_ctr > 0 || reverse_ws_ctr > 0)
  //     s = s.substr(ws_ctr, s.size() - (ws_ctr + reverse_ws_ctr));
  // }

  // inline static
  // string_t trim(string_t const& in)
  // {
  //   string_t out(in);
  //   utility::trimi(out);
  //   return out;
  // }

  // inline static
  // string_t full_trim(string_t const& in)
  // {
  //   string_t out(in);
  //   utility::full_trimi(out);
  //   return out;
  // }

  // inline static
  // void toloweri(string_t& in)
  // {
  //   std::transform(in.begin(), in.end(), in.begin(), ::tolower);
  // }

  // inline static
  // string_t tolower(string_t const& in)
  // {
  //   string_t out(in);
  //   utility::toloweri(out);
  //   return out;
  // }

  // inline static
  // void toupperi(string_t& in)
  // {
  //   std::transform(in.begin(), in.end(), in.begin(), ::toupper);
  // }

  // inline static
  // string_t toupper(string_t const& in)
  // {
  //   string_t out(in);
  //   utility::toupperi(out);
  //   return out;
  // }

  /**
   * Converts a human-readable version of a boolean into an actual one.
   *
   * Accepted boolean string formats (case-insensitive):
   *  "true", "yes", "on"
   */
  // inline static bool
  // boolify(const string_t& str)
  // {
  //   string_t s = tolower(str);

  //   if (s == "true") return true;
  //   else if (s == "yes") return true;
  //   else if (s == "on") return true;

  //   return false;
  // }

  // inline static
  // void iremove_in_string(string_t& in, char delim)
  // {
  //   size_t idx;
  //   while ((idx = in.find(delim)) != string_t::npos)
  //     in.erase(idx, 1);
  // }

  // inline static
  // void iremove_in_string(string_t& in, char delim, size_t times)
  // {
  //   size_t idx;
  //   while ((idx = in.find(delim)) != string_t::npos && --times > 0)
  //     in.erase(idx, 1);
  // }

  /**
   * Removes all occurences of a character in a string.
   *
   * @param in    The string to be manipulated
   * @param delim The character to remove
   * @param times The number of occurences to remove (0 for all)
   */
  // inline static
  // string_t remove_in_string(string_t const& in, char delim, size_t times = 0)
  // {
  //   string_t out(in);
  //   if (times == 0)
  //     iremove_in_string(out, delim);
  //   else
  //     iremove_in_string(out, delim, times);
  //   return out;
  // }


  /**
   * Checks whether the given string consists entirely of decimal numbers.
   */
  // inline static
  // bool is_decimal_nr(string_t const& in)
  // {
  //   for (string_t::const_iterator sitr = in.begin(); sitr != in.end(); ++sitr)
  //   {
  //     char c = *sitr;
  //     if (c < '0' || c > '9')
  //       return false;
  //   }

  //   return true;
  // }

  /**
   * Suffixes a string with a prefix character until it spans a certain size.
   *
   * @param size The desired final size of the string, must be greater than the current size
   * @param fill The suffix character to fill the string with
   */
  inline static
  string_t expand(string_t const& in, size_t size, char fill = ' ')
  {
    if (in.size() >= size)
      return in;

    string_t out(in);
    while (out.size() < size)
      out.push_back(fill);

    return out;
  }

  /**
   * Prefixes a string with a prefix character until it spans a certain size.
   *
   * @param size The desired final size of the string, must be greater than the current size
   * @param fill The prefix character to fill the string with
   */
  // inline static
  // string_t rexpand(string_t const& in, size_t size, char fill)
  // {
  //   if (in.size() >= size)
  //     return in;

  //   string_t out;
  //   size_t pad = size - in.size();
  //   while (out.size() < pad)
  //     out.push_back(fill);
  //   out += in;
  //   return out;
  // }

  /**
   * "Shrinks" a string by removing all occurences of a delimiter in its left-side.
   * This is really a non-whitespace left-trim helper.
   *
   * @param lsd Left-side delimiter.
   */
  // inline static
  // void ishrink(string_t& in, char lsd)
  // {
  //   size_t offset = 0;
  //   while (in.at(offset) == lsd)
  //     ++offset;

  //   in = in.substr(offset, in.size());
  // }

  /**
   * Returns true if the given string consists of all whitespace.
   *
   * Characters considered whitespace are: ' ', \n, \r, \t
   */
  // inline static
  // bool is_whitespace(string_t const& str)
  // {
  //   for (const char& c : str)
  //     if (c != ' ' && c != '\n' && c != '\r' && c != '\t')
  //       return false;

  //   return true;
  // }

  /**
   * Performs a locale-agnostic case insensitive search of a substring in a string.
   **/
  // inline static size_t
  // ci_find_substr( const string_t& str, const string_t& substr, const std::locale& loc = std::locale() )
  // {
  //   string_t::const_iterator it = std::search(
  //     str.begin(), str.end(),
  //     substr.begin(), substr.end(),
  //     [&loc](char ch1, char ch2) -> bool {
  //       return std::toupper(ch1, loc) == std::toupper(ch2, loc);
  //     });

  //   if ( it != str.end() )
  //     return it - str.begin();

  //   return std::string::npos; // not found
  // }

  // /**
  //  * Escapes a string containing JSON data in-place.
  //  */
  // inline static void
  // json_escapei( string_t& str )
  // {
  //   for (size_t i=0; i < str.size(); ++i)
  //     if (str[i] == '"' || str[i] == '\'')
  //       str.insert(i++, 1, '\\');
  //     else if (str[i] == '\n') {
  //       std::cout << "FOUND A NEWLINE IN TERM\n";
  //       str[i] = ' ';
  //     }
  // }

  // inline static string_t
  // json_escape(const string_t& str)
  // {
  //   string_t out(str);
  //   json_escapei(out);
  //   return out;
  // }

  // /**
  //  * Converts a human-readable time string into numerical seconds, format:
  //  * [number][s|m|h|d|w], eg: 5s, 10m, 30h, 4d
  //  */
  // inline static bool
  // string_to_seconds(const string_t& str, timespec* ts)
  // {
  //   if (str == "0") {
  //     ts->tv_sec = 0;
  //     return true;
  //   }

  //   int modifier = 1;
  //   switch(str.back())
  //   {
  //     case 's': case 'S': modifier = 1;   break;
  //     case 'm': case 'M': modifier = 60;  break;
  //     case 'h': case 'H': modifier = 3600;  break;
  //     case 'd': case 'D': modifier = 86400;  break;
  //     case 'w': case 'W': modifier = 604800;  break;
  //     default: return false;
  //   }

  //   string_t repl(str.begin(), str.end() - 1);
  //   try {
  //     unsigned int orig_nr = utility::convertTo<unsigned int>(repl);
  //     ts->tv_sec = orig_nr * modifier;
  //   } catch (grind::bad_conversion& e) {
  //     return false;
  //   }

  //   return true;
  // }

  // /**
  //  * Converts a human-readable filesize string into numerical bytes, format:
  //  * [number][b|k|m|g|t], eg: 5M, 10K, 1G, 3T
  //  */
  // inline static bool
  // string_to_bytes(const string_t& str, uint64_t *sz)
  // {
  //   if (str == "0") {
  //     (*sz) = 0;
  //     return true;
  //   }

  //   uint64_t modifier = 1;
  //   switch(str.back())
  //   {
  //     case 'b': case 'B': modifier = 1;   break;
  //     case 'k': case 'K': modifier = 1024;  break;
  //     case 'm': case 'M': modifier = 1048576;  break;
  //     case 'g': case 'G': modifier = 1073741824;  break;
  //     case 't': case 'T': modifier = 1099511627776;  break;
  //     default: return false;
  //   }

  //   string_t repl(str.begin(), str.end() - 1);
  //   try {
  //     unsigned int orig_nr = utility::convertTo<unsigned int>(repl);
  //     (*sz) = orig_nr * modifier;
  //   } catch (grind::bad_conversion& e) {
  //     return false;
  //   }

  //   return true;
  // }

  // /**
  //  * Returns the current time in the format: "MM-DD-YYYY HH:mm:SS"
  //  */
  // inline static string_t
  // pretty_time_now()
  // {
  //   struct tm *pTime;
  //   time_t ctTime; time(&ctTime);
  //   pTime = localtime( &ctTime );
  //   std::ostringstream message;
  //   message
  //     << std::setw(2) << std::setfill('0') << pTime->tm_mon
  //     << '-' << std::setw(2) << std::setfill('0') << pTime->tm_mday
  //     << '-' << std::setw(4) << std::setfill('0') << pTime->tm_year + 1900
  //     << ' ' << std::setw(2) << std::setfill('0') << pTime->tm_hour
  //     << ":" << std::setw(2) << std::setfill('0') << pTime->tm_min
  //     << ":" << std::setw(2) << std::setfill('0') << pTime->tm_sec;

  //   return message.str();
  // }

  // bool html_encode(string_t &dest, const string_t& src);
  // bool html_decode(string_t &dest, const string_t& src);

  // /**
  //  * Replaces all or a number of occurences of a pattern with another within a string.
  //  *
  //  * @param str   The string to be searched and replaced if appropriate
  //  * @param orig  The pattern string to look for and replace
  //  * @param repl  The string to use as a replacement for @orig
  //  * @param times The number of occurences to replace if found (0 for all)
  //  */
  // inline void
  // replace_in_string(string_t &str, string_t const &orig, string_t const &repl) {
  //   size_t match_pos = str.find(orig);
  //   while (match_pos != string_t::npos) {
  //     str.replace(match_pos, orig.size(), repl);
  //     match_pos = str.find(orig);
  //   }
  // }

  // string_t    get_hostname();
  // const char* get_hostname_cstr();

} // namespace utility
} // namespace grind

#endif
