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

#include "connection.hpp"
// #include <pcrecpp.h>
#include <boost/regex.hpp>

namespace grind {

  // static pcrecpp::RE* re_ = nullptr;
  static boost::regex regex_;
  connection::connection(boost::asio::io_service& io_service, script_engine& se)
  : socket_(io_service),
    strand_(io_service),
    // request_(message::max_length),
    // response_(message::max_length),
    se_(se),
    dispatcher_(io_service),
    close_handler_()
  {
    // regex_ = boost::regex("([A-Z]{1}[a-z}{2}) ([0-9]+) ([0-9]{2}:[0-9]{2}:[0-9]{2})");
    // if (!re_) {
    //   pcrecpp::RE_Options opts_;
    //   string_t pattern = "([A-Z]{1}[a-z}{2}) ([0-9]+) ([0-9]{2}:[0-9]{2}:[0-9]{2})";
    //   re_ = new pcrecpp::RE(pattern, opts_);

    //   if (!re_->error().empty())
    //   {
    //     string_t msg = "PCRE compilation failed for pattern '" + pattern + "', error: " + re_->error();
    //     delete re_;
    //     re_ = nullptr;
    //     throw std::runtime_error(msg);
    //   }
    // }
  }

  connection::~connection() {
  }

  boost::asio::ip::tcp::socket& connection::socket() {
    return socket_;
  }

  dispatcher& connection::get_dispatcher() {
    return dispatcher_;
  }

  void connection::assign_close_handler(close_handler_t in_cb)
  {
    close_handler_ = in_cb;
  }

  void connection::start() {
    socket_.set_option(boost::asio::ip::tcp::no_delay(true));
    boost::asio::socket_base::non_blocking_io command(true);
    socket_.io_control(command);

    read();
  }

  void connection::stop() {
    boost::system::error_code ignored_ec;

    // initiate graceful connection closure & stop all asynchronous ops
    socket_.cancel();
    socket_.shutdown(boost::asio::ip::tcp::socket::shutdown_both, ignored_ec);

    if (close_handler_)
      close_handler_(shared_from_this());
  }

  void connection::read() {
    inbound_.reset();
    // request_.consume(request_.size());
    for (char& c : data_)
      c = '\0';

    socket_.async_read_some(
      boost::asio::buffer(data_, 1024),
    // async_read_until(
      // socket_,
      // request_,
      // regex_,
      // "Jun 25 12:31:48",
    //   // 4096,
      boost::bind(
        &connection::on_read,
        this,
        boost::asio::placeholders::error,
        boost::asio::placeholders::bytes_transferred
      )
    );
  }

  static unsigned long int msg_id = 0;

  void
  connection::on_read( const boost::system::error_code& e, std::size_t bytes_transferred)
  {
    if (!e) {
      std::cout << "Received " << bytes_transferred << " bytes\n";
      // we use a loop since a buffer might hold more than 1 msg
      // std::ostringstream s;
      // s << &request_;
      // std::istream is(&request_);
      // s << is;
      // for (int i = 0; i < bytes_transferred; ++i)
        // s << is.get();
      // string_t data_ = s.str();

      // std::cout << "Message[" << ++msg_id << "] received: '" << data_ << "'";
      string_t data(data_);
      std::cout << "Message[" << ++msg_id << "] received: '" << string_t(data) << "'";
      fflush(stdout);
      // while (request_.size() > 0 && inbound_.from_stream(request_)) {
        // dispatcher_.deliver(inbound_);
      // }
      se_.relay(data);

      // read next message
      read();

    } else {
      stop();
    }
  }

  // void connection::send(message &msg) {
  //   strand_.post(boost::bind(&connection::do_send, this, msg));
  // }

  // void connection::do_send(message& msg)
  // {
  //   outbound_ = message(msg);

  //   if (outbound_.feedback == message_feedback::unassigned)
  //     outbound_.feedback = message_feedback::ok;

  //   outbound_.to_stream(response_);

  //   boost::system::error_code ec;
  //   size_t n = boost::asio::write(socket_, response_.data(), boost::asio::transfer_all(), ec);

  //   if (!ec) {
  //     response_.consume(n);
  //   } else
  //     stop();
  // }

} // namespace grind
