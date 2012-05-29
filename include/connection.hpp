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

#ifndef H_GRIND_CONNECTION_H
#define H_GRIND_CONNECTION_H

#include <boost/asio.hpp>
#include <boost/array.hpp>
#include <boost/bind.hpp>
#include <boost/noncopyable.hpp>
#include <boost/function.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/enable_shared_from_this.hpp>

#include "grind.hpp"
#include "dispatcher.hpp"
#include "message.hpp"

namespace grind {

  class connection;
  typedef boost::shared_ptr<connection> connection_ptr;
  typedef boost::function<void(connection_ptr)> close_handler_t;

  /**
   * \addtogroup Console
   * @{
   * @class connection
   * A privileged admin connection from a system administrator used
   * by the Console.
   **/
  class connection
    : public boost::enable_shared_from_this<connection>
    // : public logger
  {
  public:
    explicit connection(boost::asio::io_service& io_service);
    virtual ~connection();

    boost::asio::ip::tcp::socket& socket();

    virtual void start();
    virtual void stop();

    /**
     * Send a message to the client.
     *
     * The message's feedback field will be set to message_feedback::ok if it's unassigned.
     */
    virtual void send(message&);

    /**
     * The dispatcher responsible for notifying listeners to incoming messages.
     *
     * This handle is necessary for you to
     */
    dispatcher& get_dispatcher();

    /** Register a callback that will be called when this connection has stopped. */
    void assign_close_handler(close_handler_t);

  protected:
    boost::asio::ip::tcp::socket socket_;
    boost::asio::strand           strand_;
    boost::asio::mutable_buffer   body_;
    boost::asio::streambuf        request_;
    boost::asio::streambuf        response_;

    dispatcher  dispatcher_;
    message     outbound_, inbound_;

    close_handler_t   close_handler_;

  protected:
    friend class console;

    virtual void read();
    virtual void on_read( const boost::system::error_code& error, std::size_t bytes_transferred);

    virtual void do_send(message&);
  };

  /** @} */

} // namespace grind

#endif
