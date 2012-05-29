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

#ifndef H_GRIND_DISPATCHER_H
#define H_GRIND_DISPATCHER_H

#include <boost/asio.hpp>
#include <boost/array.hpp>
#include <boost/function.hpp>
#include <boost/bind.hpp>
#include <exception>
#include <stdexcept>
#include <map>
#include <deque>
#include "message.hpp"
 #include <functional>

namespace grind {

  using boost::asio::ip::tcp;

  /**
   * \addtogroup Core
   * @{
   *  @class dispatcher
   *    Dispatches messages received over admin connections to subscribed
   *    parties.
   */
  class dispatcher {
    public:
      typedef std::function<void(const message&)> msg_handler_t;

      dispatcher(boost::asio::io_service&);
      virtual ~dispatcher();

      /**
       * Registers the given callback to be notified whenever a message of the
       * specified UID is received and hooked.
       */
      template <typename T>
      void bind(message_uid uid, T* inT, void (T::*handler)(const message&)) {
        bind(uid, boost::bind(handler, inT, _1));
      }

      void bind(message_uid uid, msg_handler_t handler) {
        // register message if it isn't already
        msg_handlers_t::iterator binder = msg_handlers_.find(uid);
        if (binder == msg_handlers_.end())
        {
          binder = msg_handlers_.insert(make_pair(uid, std::vector<msg_handler_t>() )).first;
        }

        binder->second.push_back( handler );
      }

      /** Removes all callbacks registerd to this message. */
      void unbind(message_uid uid);

      /**
       * Delivers a local copy of the message to bound handlers.
       *
       * @note: the message might not be dispatched immediately, as it will be
       * queued internally and later on dispatched through the strand object
       * unless the immediate flag is set
       */
      void deliver(const message&, bool immediate = false);

      /**
       * Clears all message subscription.
       */
      void reset();

    private:
      void dispatch();

      boost::asio::strand strand_;

      typedef std::map< message_uid , std::vector<msg_handler_t> > msg_handlers_t;
      msg_handlers_t msg_handlers_;

      std::deque<message> events;
  };

  /** @} */

} // namespace grind

#endif
