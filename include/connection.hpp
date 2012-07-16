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
#include "logger.hpp"
#include "script_engine.hpp"

namespace grind {

  class connection;
  class feeder;
  typedef boost::shared_ptr<connection> connection_ptr;
  typedef boost::function<void(connection_ptr)> close_handler_t;
  typedef boost::asio::ip::tcp::socket socket_t;
  typedef boost::asio::strand strand_t;
  typedef boost::asio::streambuf streambuf_t;

  typedef char buf_t;

  /**
   * \addtogroup Console
   * @{
   * @class connection
   * Represents a stream connection from a feeder, or a consumer from a watcher.
   **/
  class connection
    : public boost::enable_shared_from_this<connection>,
      public logger
  {
  public:
    
    enum {
      FEEDER_CONNECTION,
      WATCHER_CONNECTION
    };

    explicit connection(boost::asio::io_service& io_service, script_engine&, int type, feeder* = nullptr);
    virtual ~connection();

    boost::asio::ip::tcp::socket& socket();

    void set_type(int);
    int type();
    bool is_watcher() const;
    bool is_feeder() const;
    
    void start();
    void stop();
    
    void send(string_t);
    string_t const& whois() const;

    /** Register a callback that will be called when this connection has stopped. */
    void assign_close_handler(close_handler_t);

  protected:
    enum { BUFSZ = 1024 };

    socket_t          socket_;
    strand_t          strand_;
    script_engine     &se_;
    char              data_[BUFSZ];
    streambuf_t       response_;
    close_handler_t   close_handler_;
    int               type_;
    string_t          remote_host_;
    ushort            remote_port_;
    string_t          whois_;
    feeder*           feeder_;

  protected:
    void read();
    void on_read( const boost::system::error_code& error, std::size_t bytes_transferred);
    void do_send(string_t, bool single_buffer = false);
  };

  /** @} */

} // namespace grind

#endif
