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

#include <iostream>
#include <fstream>
#include <string>
#include <boost/asio.hpp>
#include <boost/thread.hpp>
#include <boost/bind.hpp>
#include <boost/regex.hpp>

#include <pthread.h>
#include <signal.h>

#include "kernel.hpp"
#include "utility.hpp"

int print_usage() {
  using std::cout;
  using grind::utility::expand;

  static int keysz = 20;

  cout << "grind: a log analyzing and aggregation tool\n";
  cout << "USAGE: grind [OPTIONS]\n\n";
  
  cout << "Options:\n";
  cout << expand("-c PATH", keysz) << "path to grind configuration script (config.lua)\n";
  cout << expand("-h, --help", keysz) << "display this help listing\n";

  return 0;
}

int main(int argc, char** argv)
{
  using grind::string_t;
  grind::kernel kernel;

  string_t config_file = "";
  if (argc > 1) {
    for (int i = 1; i < argc; ++i) {
      string_t arg(argv[i]);

      if (arg == "-c") {
        if (argc < i + 1) {
          std::cerr << "invalid argument '-c'; missing path to config file\n";
          return 0;
        }

        config_file = argv[++i];
      }
      else if (arg == "-h" || arg == "--help") {
        return print_usage();
      }
      if (arg == "-l") {
        if (argc < i + 1) {
          std::cerr << "invalid argument '-l'; missing log level\n";
          return 0;
        }

        kernel.cfg.log_level = *argv[++i];
      }
    }
  }

  // block all signals for background thread
  sigset_t new_mask;
  sigfillset(&new_mask);
  sigset_t old_mask;
  pthread_sigmask(SIG_BLOCK, &new_mask, &old_mask);

  kernel.init(config_file);

  if (!kernel.is_init()) {
    kernel.cleanup();

    return 1;
  }
  
  boost::thread t(boost::bind(&grind::kernel::start, &kernel));

  // restore previous signals
  pthread_sigmask(SIG_SETMASK, &old_mask, 0);

  // wait for signal indicating time to shut down
  sigset_t wait_mask;
  sigemptyset(&wait_mask);
  sigaddset(&wait_mask, SIGINT);
  sigaddset(&wait_mask, SIGQUIT);
  sigaddset(&wait_mask, SIGTERM);
  pthread_sigmask(SIG_BLOCK, &wait_mask, 0);
  int sig = 0;
  sigwait(&wait_mask, &sig);

  if (kernel.is_running())
    kernel.stop();

  kernel.cleanup();

  t.join();

  return 0;
}
