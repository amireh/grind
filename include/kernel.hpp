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

#ifndef H_GRIND_KERNEL_H
#define H_GRIND_KERNEL_H

#include "grind.hpp"
#include "logger.hpp"
#include "configurable.hpp"
#include "watcher.hpp"
#include "script_engine.hpp"

#include <string>
#include <vector>
#include <list>

// Boost
#include <boost/asio.hpp>
#include <boost/bind.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/thread.hpp>
#include <boost/interprocess/sync/interprocess_mutex.hpp>
#include <boost/interprocess/sync/scoped_lock.hpp>

namespace grind {

  class connection;
  typedef boost::shared_ptr<connection> connection_ptr;
  typedef boost::interprocess::scoped_lock<boost::interprocess::interprocess_mutex> scoped_lock;

  class kernel : public logger, public configurable {
  public:
    struct {
      string_t  listen_interface; /* default: 0.0.0.0 */
      string_t  port;             /* default: 11142 */
      string_t  watched_file;
    } cfg;

    explicit kernel();
    virtual ~kernel();
    kernel(const kernel&) = delete;
    kernel& operator=(const kernel&) = delete;

    void init();

    virtual void configure(string_t const& path_to_config);

    /**
     * Starts the kernel, launches the Watcher, and begins accepting watcher
     * terminals.
     */
    void start();

    /** Stops the kernel and the watcher. */
    void stop();

    /** must be called after the kernel is stopped */
    void cleanup();

    bool is_running() const;

    void set_option(string_t const& key, string_t const& value);

  protected:
    // marks the connection as dead and will be removed sometime later
    void close(connection_ptr);

  private:
    // a thread handling io_service::run()
    void work();

    void accept();
    void on_accept(const boost::system::error_code &e);

    boost::asio::io_service io_service_;
    boost::asio::strand strand_;
    boost::thread_group workers_;
    boost::asio::ip::tcp::acceptor acceptor_;

    // the next connection to be accepted
    connection_ptr new_connection_;
    std::list<connection_ptr> connections_;
    std::list<connection_ptr> paused_connections_;
    boost::interprocess::interprocess_mutex conn_mtx_;

    bool running_; /** set to TRUE when the kernel is online and accepting connections */
    bool init_; /** set to TRUE when the kernel has allocated its resources properly */

    std::vector<watcher*> watchers_;

    script_engine se_;
  };


} // namespace grind

#endif // H_GRIND_KERNEL_H
