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

#ifndef H_GRIND_CONFIGURATOR_H
#define H_GRIND_CONFIGURATOR_H

#include "grind.hpp"
#include "logger.hpp"
#include "configurable.hpp"

#include <map>
#include <sstream>
#include <fstream>

#include <yajl/yajl_parse.h>
#include <yajl/yajl_gen.h>

namespace grind {

  /**
   * \addtogroup Core
   * @{
   * @class configurator
   *
   * Parses a JSON configuration sheet and calls all subscribed configurable objects
   * with their options.
   */
  class configurator : public logger {
  public:

    configurator(string_t const& json_data);
    configurator(std::ifstream& json_file_handle);

    virtual ~configurator();
    configurator(const configurator&) = delete;
    configurator& operator=(const configurator&) = delete;

    static void init();
    static void silence();

    typedef struct {
      bool     valid;
      string_t status;
    } parser_rc;

    /**
     * performs the actual parsing and configuration of subscribed instances
     */
    void run();

    parser_rc validate(string_t const& json);

    /**
     * subscribed the given configurable to its configuration context;
     * once that context is encountered in a configuration file, the object
     * will be passed the options to handle them
     *
     * @note
     * a context can be assigned at most 1 configurable at any time,
     * but a configurable can handle many contexts
     */
    static void subscribe(configurable*, string_t const& context);
    static void unsubscribe(configurable*, string_t const& context);

    int __on_json_map_start();
    int __on_json_map_key(const unsigned char*, size_t);
    int __on_json_map_val(const unsigned char*, size_t);
    int __on_json_map_end();
    int __on_json_array_start();
    int __on_json_array_end();

  private:

    /**
     * Is the JSON key a keyword reserved by the configurator?
     *
     * Currently, only "include" is reserved.
     * */
    bool is_reserved(const string_t& ctx);

    void parse_string(string_t const& data);

    bool load_file(std::ifstream &fs, string_t& out_buf);

    typedef std::list<configurable*> configurables_t;
    typedef std::map<string_t, configurables_t> subs_t;
    static subs_t subs_;
    static bool init_;
    static bool silent_;

    string_t data_;

    string_t        curr_key_;
    string_t        curr_val_;
    string_t        curr_ctx_;
    int             depth_;
    configurables_t *curr_subs_;

    enum {
      yajl_continue = 1, /** continue parsing */
      yajl_stop = 0 /** stop parsing */
    };

  };
  /** @} */
} // namespace grind

#endif // H_GRIND_LOG_MANAGER_H
