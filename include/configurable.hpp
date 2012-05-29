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

#ifndef H_GRIND_CONFIGURABLE_H
#define H_GRIND_CONFIGURABLE_H

#include "grind.hpp"
#include <array>

namespace grind {

  class configurator;

  /**
   * \addtogroup Core
   * @{
   * @class configurable
   *
   * Configurables can register themselves with the dakapi server to be called
   * when the server configuration is parsed and processed.
   */
  class configurable {
  public:

    /**
     * Default ctor, does not subscribe to any context: you must manually do that by calling
     * configurable::subscribe_context()
     */
    explicit configurable();

    /**
     * Subscribes this instance to every given context
     *
     * @note
     * You clearly don't have to call configurator::subscribe_context() anymore
     * if you use this constructor.
     */
    explicit configurable(std::vector<string_t> contexts);

    configurable(const configurable&);
    configurable& operator=(const configurable&);
    virtual ~configurable();

    /** called whenever a cfg setting is encountered and parsed */
    virtual void set_option(string_t const& key, string_t const& value)=0;

    inline virtual void on_array_start() {}
    inline virtual void on_array_end() {}

    inline virtual void on_map_start() {}
    inline virtual void on_map_key(string_t const&) {}
    inline virtual void on_map_end() {}

    /**
     * Called when the config section is fully parsed, implementations
     * can do the actual configuration here if needed.
     *
     * @note
     * Sometimes this isn't really required as an implementation could configure
     * itself on-the-fly as set_option() is called, but others might have dependant
     * options.
     */
    inline virtual void configure() { }

    /** is this instance subscribed to the passed configuration context? */
    bool subscribed_to_context(string_t const&);

  protected:
    friend class configurator;

    /** this instance will be called whenever the given context is encountered */
    void subscribe_context(string_t const&);

    /**
     * when a configurable is subscribed to more than 1 context,
     * this string can be used to determine the current context being parsed
     */
    string_t current_ctx_;

    std::vector<string_t> cfg_contexts_;

    void copy(const configurable& src);
  };
  /** @} */
}

#endif
