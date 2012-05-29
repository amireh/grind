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

#include "configurable.hpp"
#include "configurator.hpp"

namespace grind {

  configurable::configurable()
  {
  }

  configurable::configurable(std::vector<string_t> contexts)
  {
    for (auto ctx : contexts)
      subscribe_context(ctx);
  }

  configurable& configurable::operator=(const configurable& rhs)
  {
    if (this != &rhs) copy(rhs);

    return *this;
  }

  configurable::configurable(const configurable& src)
  {
    copy(src);
  }

  configurable::~configurable()
  {
    for (auto ctx : cfg_contexts_) {
      configurator::unsubscribe(this, ctx);
    }
    cfg_contexts_.clear();
  }

  void configurable::copy(const configurable& src)
  {
    current_ctx_ = src.current_ctx_;
    cfg_contexts_ = src.cfg_contexts_;
  }

  void configurable::subscribe_context(string_t const& ctx)
  {
    configurator::subscribe(this, ctx);
    cfg_contexts_.push_back(ctx);
  }

  bool configurable::subscribed_to_context(string_t const& in_ctx)
  {
    for (auto ctx : cfg_contexts_)
      if (ctx == in_ctx) return true;

    return false;
  }

}
