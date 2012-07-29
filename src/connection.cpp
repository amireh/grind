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
#include "utility.hpp"
#include "kernel.hpp"

namespace grind {

  connection::connection(boost::asio::io_service& io_service, script_engine& se, int type, feeder* f)
  : socket_(io_service),
    strand_(io_service),
    se_(se),
    logger("connection"),
    type_(type),
    close_handler_(),
    feeder_(f)
  {
  }

  connection::~connection() {
    // std::cout << "connection being destroyed\n";
  }

  boost::asio::ip::tcp::socket& connection::socket() {
    return socket_;
  }

  void connection::assign_close_handler(close_handler_t in_cb)
  {
    close_handler_ = in_cb;
  }

  void connection::start() {
    socket_.set_option(boost::asio::ip::tcp::no_delay(true));
    boost::asio::socket_base::non_blocking_io command(true);
    socket_.io_control(command);


    if (type_ == WATCHER_CONNECTION) {
      remote_host_ = socket_.remote_endpoint().address().to_string();
      remote_port_ = socket_.remote_endpoint().port();
      whois_ = remote_host_ + ":" + utility::stringify(remote_port_);

      se_.pass_to_lua("grind.add_watcher", NULL, 0, 1, "grind::connection", this);
    }

    info() << "connection started from: " << whois();
    
    read();
  }

  void connection::stop() {
    if (type_ == WATCHER_CONNECTION) {
      se_.pass_to_lua("grind.remove_watcher", NULL, 0, 1, "grind::connection", this);
    }
    
    boost::system::error_code ignored_ec;

    // initiate graceful connection closure & stop all asynchronous ops
    socket_.cancel();
    socket_.shutdown(boost::asio::ip::tcp::socket::shutdown_both, ignored_ec);

    if (close_handler_)
      close_handler_(shared_from_this());
  }

  void connection::set_type(int type) {
    type_ = type;
  }

  void connection::read() {
    for (int i = 0; i < BUFSZ; ++i)
      data_[i] = '\0';
    // for (char& c : data_)
      // c = '\0';

    socket_.async_read_some(
      boost::asio::buffer(data_, BUFSZ),
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

      // info() << "Received " << bytes_transferred << " bytes"; 
      data_[BUFSZ] = '\0';
      string_t data(data_);

      if (type_ == WATCHER_CONNECTION) {
        // it's an API command
        se_.handle_cmd(data, this);
      } else {
        // it's a log message
        se_.relay(data, feeder_);
      }

      // read next message
      read();

    } else {
      stop();
    }
  }

  void connection::send(string_t msg) {
    strand_.post(boost::bind(&connection::do_send, this, msg, false));
  }

  void connection::do_send(string_t msg, bool single_buffer)
  {
    boost::system::error_code ec;
    size_t n = boost::asio::write(socket_, boost::asio::buffer(msg.c_str(), msg.size()), boost::asio::transfer_all(), ec);

    // debug() << "wrote " << n << " out of " << msg.size() << " bytes";

    // assert(n == msg.size());

    if (ec) {
      return stop();
    }
  }

  int connection::type() {
    return type_;
  }
  bool connection::is_watcher() const {
    return type_ == WATCHER_CONNECTION;
  }
  bool connection::is_feeder() const {
    return type_ == FEEDER_CONNECTION;
  }

  string_t const& connection::whois() const {
    return  whois_;
  }
  
} // namespace grind
