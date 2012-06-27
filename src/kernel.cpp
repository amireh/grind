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
#include "configurator.hpp"

namespace grind {

  kernel::kernel()
  : logger("grind"),
    configurable({ "grind" }),
    io_service_(),
    strand_(io_service_),
    acceptor_(io_service_),
    watcher_acceptor_(io_service_),
    new_connection_(),
    new_watcher_connection_(),
    running_(false),
    init_(false),
    se_(*this)
  {
    cfg.listen_interface = "0.0.0.0";
    cfg.watcher_interface = "0.0.0.0";
    cfg.port = "11142";
    cfg.watcher_port = "11144";
  }

  kernel::~kernel()
  {
  }

	/* +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ *
	 *	bootstrap
	 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */

  void kernel::init()
  {
    log_manager::singleton().init();
    log_manager::singleton().configure();
  }

  void kernel::configure(string_t const& path_to_config) {
    info() << "configuring using file @ " << path_to_config;

    string_t data;
    std::ifstream cfg_stream(path_to_config);
    if (cfg_stream.is_open() && cfg_stream.good()) {
      cfg_stream.seekg(0, std::ios::end);
      data.reserve(cfg_stream.tellg());
      cfg_stream.seekg(0, std::ios::beg);

      data.assign((std::istreambuf_iterator<char>(cfg_stream)),
                       std::istreambuf_iterator<char>());
    } else {
      error() << "unable to configure; invalid config file @ " << path_to_config;
      return;
    }

    configurator c(data);
    c.run();
  }

  void kernel::start()
  {
    info() << "accepting logs on: " << cfg.listen_interface << ":" << cfg.port;
    info() << "accepting watchers on: " << cfg.watcher_interface << ":" << cfg.watcher_port;

    se_.start();

    init_ = true;

    // open the client acceptor with the option to reuse the address (i.e. SO_REUSEADDR).
    {
      // boost::asio::ip::tcp::resolver resolver(io_service_pool_.get_io_service());
      boost::asio::ip::tcp::resolver resolver(io_service_);
      boost::asio::ip::tcp::resolver::query query(cfg.listen_interface, cfg.port);
      boost::asio::ip::tcp::endpoint endpoint = *resolver.resolve(query);
      acceptor_.open(endpoint.protocol());
      acceptor_.set_option(boost::asio::ip::tcp::acceptor::reuse_address(true));
      acceptor_.bind(endpoint);
      acceptor_.listen();

      // accept connections
      accept();
    }

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

    // if (!cfg.watched_file.empty()) {
      // watchers_.push_back(new watcher(cfg.watched_file));
      // workers_.create_thread(boost::bind(&watcher::watch, watchers_.back()));
      // watchers_.back()->watch();
    // }

    workers_.create_thread(boost::bind(&kernel::work, boost::ref(this)));


    // wait for all threads in the pool to exit
    workers_.join_all();
  }

  void kernel::cleanup()
  {
    if (!init_) {
      std::cerr
        << "WARNING: attempting to clean up the kernel when it has "
        << "already been cleaned, or not run at all!";
      return;
    }

    info() << "cleaning up";

    new_connection_.reset();
    new_watcher_connection_.reset();
    connections_.clear();

    // for (auto watcher : watchers_)
      // watcher->stop();

    // while (!watchers_.empty()) {
      // delete watchers_.back();
      // watchers_.pop_back();
    // }

    se_.stop();

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

    connections_.clear();
    new_connection_.reset();

    io_service_.stop();

    info() << "stopped";
    running_ = false;
  }

	/* +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ *
	 *	main routines
	 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */
   void kernel::accept() {
      new_connection_.reset(new connection(io_service_, se_, connection::RECEIVER_CONNECTION));
      new_connection_->assign_close_handler(boost::bind(&kernel::close, this, _1));
      acceptor_.async_accept(new_connection_->socket(),
          boost::bind(&kernel::on_accept, this,
            boost::asio::placeholders::error));
   }

   void kernel::on_accept(const boost::system::error_code &e) {
    if (!e)
    {
      connections_.push_back(new_connection_);
      new_connection_->start();

      accept();
    } else {
      error() << "couldn't accept connection! " << e;
      throw std::runtime_error("unable to accept connection, see log for more info");
    }
  }
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

  void kernel::set_option(string_t const& key, string_t const& value)
  {
    if (key == "listen_interface")
      cfg.listen_interface = value;
    else if (key == "port")
      cfg.port = value;
    else if (key == "watcher_interface")
      cfg.watcher_interface = value;
    else if (key == "watcher_port")
      cfg.watcher_port = value;

    else {
      log_->warnStream() << "unknown grind config setting '"
        << key << "' => '" << value << "', discarding";
    }
  }

  void kernel::broadcast(string_t const& msg) {
    conn_mtx_.lock();

    int nr_watchers = 0;
    for (auto c : connections_) {
      c->send(msg);
      if (c->is_watcher())
        ++nr_watchers;      
    }

    info() << "broadcasting to " << nr_watchers << " watchers";
    conn_mtx_.unlock();
  }

} // namespace grind
