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

#include <ctime>
#include <csignal>
#include <fstream>

#include "kernel.hpp"
#include "connection.hpp"
#include "utility.hpp"

namespace grind {

  kernel::kernel()
  : logger("grind"),
    io_service_(),
    strand_(io_service_),
    watcher_acceptor_(io_service_),
    new_watcher_connection_(),
    running_(false),
    init_(false),
    se_(*this)
  {
    cfg.feeder_interface = "0.0.0.0";
    cfg.watcher_interface = "0.0.0.0";
    cfg.watcher_port = "11142";
  }

  kernel::~kernel()
  {
  }

	/* +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ *
	 *	bootstrap
	 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */

  bool kernel::init(string_t const& path_to_config) {
    log_manager::singleton().init();
    log_manager::singleton().configure();

    try {
      se_.start(path_to_config);
    } catch (std::exception& e) {
      error() << e.what();
      return false;
    }

    init_ = se_.is_running();
    return init_;
  }

  void kernel::start()
  {
    info() << "accepting logs on: " << cfg.feeder_interface;
    info() << "accepting watchers on: " << cfg.watcher_interface << ":" << cfg.watcher_port;

    // open the client acceptor with the option to reuse the address (i.e. SO_REUSEADDR).
    {
      // boost::asio::ip::tcp::resolver resolver(io_service_pool_.get_io_service());
      boost::asio::ip::tcp::resolver resolver(io_service_);
      boost::asio::ip::tcp::resolver::query query(cfg.watcher_interface, cfg.watcher_port);
      boost::asio::ip::tcp::endpoint endpoint = *resolver.resolve(query);
      watcher_acceptor_.open(endpoint.protocol());
      watcher_acceptor_.set_option(boost::asio::ip::tcp::acceptor::reuse_address(true));
      watcher_acceptor_.bind(endpoint);
      watcher_acceptor_.listen();

      // accept connections
      accept_watcher();
    }

    running_ = true;

    workers_.create_thread(boost::bind(&kernel::work, boost::ref(this)));

    // wait for all threads in the pool to exit
    workers_.join_all();
  }

  void kernel::cleanup()
  {
    info() << "cleaning up";

    if (is_running())
      stop();

    for (auto pair : feeders_)
      delete pair.second;

    feeders_.clear();

    log_manager::singleton().cleanup();
    delete &log_manager::singleton();

    init_ = false;
  }

  void kernel::work() {
    try {
      io_service_.run();
    } catch (std::exception& e) {
      std::cerr << "an exception caught in a worker, aborting: " << e.what();
      throw e;
    }
  }

  void kernel::stop() {
    if (!is_running()) {
      warn()
        << "attempting to stop the kernel when it's not running!";

      if (init_)
        error() << "received stop() command when I'm already offline";

      return;
    }

    info() << "shutting down gracefully, waiting for current terminals to disengage, please wait";

    for (auto conn : connections_)
      conn->stop();
    for (auto pair : feeders_)
      pair.second->stop();

    new_watcher_connection_.reset();
    connections_.clear();

    io_service_.stop();
    
    se_.stop();

    info() << "stopped";
    running_ = false;
  }

	/* +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ *
	 *	main routines
	 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */
   void kernel::accept_watcher() {
      new_watcher_connection_.reset(new connection(io_service_, se_, connection::WATCHER_CONNECTION));
      new_watcher_connection_->assign_close_handler(boost::bind(&kernel::close, this, _1));
      watcher_acceptor_.async_accept(new_watcher_connection_->socket(),
          boost::bind(&kernel::on_watcher_accepted, this,
            boost::asio::placeholders::error));
   }

   void kernel::on_watcher_accepted(const boost::system::error_code &e) {
    if (!e)
    {
      connections_.push_back(new_watcher_connection_);
      new_watcher_connection_->start();

      accept_watcher();
    } else {
      error() << "couldn't accept connection! " << e;
      throw std::runtime_error("unable to accept connection, see log for more info");
    }
  }

  void kernel::close(connection_ptr conn) {
    strand_.post([&, conn]() -> void {
      scoped_lock lock(conn_mtx_);
      connections_.remove(conn);
    });
  }

  bool kernel::is_running() const {
    return running_;
  }
  bool kernel::is_init() const {
    return init_;
  }

  bool kernel::is_port_available(int port) const {
    for (auto pair : feeders_) {
      feeder *f = pair.second;
      if (f->port() == port) return false;
    }

    return true;
  }

  bool kernel::register_feeder(string_t const& glabel, int port) {
    if (is_feeder_registered(glabel)) {
      error()
        << "A feeder for the application group " << glabel
        << " is already registered, ignoring.";

      return false;
    }

    feeder *f = new feeder(io_service_, *this, se_, glabel, port);
    try {
      f->listen();
    } catch(std::exception& e) {
      error()
        << "Feeder was unable to listen; " << e.what();

      return false;
    }

    feeder_mtx_.lock();
    feeders_.insert(std::make_pair(glabel, f));
    info() << "Feeder registered: " << f->label();
    feeder_mtx_.unlock();
    return true;
  }

  void kernel::remove_feeder(const feeder* const f) {
    string_t glabel = f->label();
    strand_.post([&, glabel]() -> void {
      info() << "Removing feeder " << glabel;

      feeder_mtx_.lock();
      delete feeders_.find(glabel)->second;
      feeders_.erase(glabel);
      feeder_mtx_.unlock();
    });
  }

  bool kernel::is_feeder_registered(string_t const& glabel) {
    feeder_mtx_.lock();
    auto iter = feeders_.find(glabel);
    feeder_mtx_.unlock();

    return iter != feeders_.end();
  }

  feeder::feeder(io_service_t& io_service, kernel& in_kernel, script_engine& se, string_t const& label, int port)
  : io_service_(io_service),
    acceptor_(io_service),
    kernel_(in_kernel),
    script_engine_(se),
    label_(label),
    port_(port),
    conn_()
  {

  }
  feeder::~feeder() {
    if (acceptor_.is_open()) {
      acceptor_.cancel();
      acceptor_.close();
    }
  }

  void feeder::listen() {
    // open the client acceptor with the option to reuse the address (i.e. SO_REUSEADDR).
    boost::asio::ip::tcp::resolver resolver(io_service_);
    boost::asio::ip::tcp::resolver::query query(kernel_.cfg.feeder_interface, utility::stringify(port_));
    boost::asio::ip::tcp::endpoint endpoint = *resolver.resolve(query);
    acceptor_.open(endpoint.protocol());
    acceptor_.set_option(boost::asio::ip::tcp::acceptor::reuse_address(true));
    acceptor_.bind(endpoint);
    acceptor_.listen();

    // accept connections
    accept();
  }

  void feeder::accept() {
    conn_.reset(new connection(io_service_, script_engine_, connection::FEEDER_CONNECTION, this));
    conn_->assign_close_handler(boost::bind(&feeder::close, this, _1));
    acceptor_.async_accept(conn_->socket(), boost::bind(&feeder::on_accept, this, boost::asio::placeholders::error));

  }

  void feeder::on_accept(const boost::system::error_code &e) {
    if (!e)
    {
      connections_.push_back(conn_);
      conn_->start();

      accept();
    } else {
      GRIND_LOG->errorStream() << "couldn't accept connection! " << e;
      kernel_.remove_feeder(this);
    }
  }  

  void feeder::close(connection_ptr conn) {
    {
      scoped_lock lock(conn_mtx_);

      connections_.remove(conn);
    }
  }

  int feeder::port() const { return port_; }
  string_t const& feeder::label() const { return label_; }

  void feeder::stop() {
    scoped_lock lock(conn_mtx_);

    for (auto c : connections_) {
      c->assign_close_handler(0);
      c->stop();
      
    }

    connections_.clear();
  }

} // namespace grind
