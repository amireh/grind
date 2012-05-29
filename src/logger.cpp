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

#include "logger.hpp"

namespace grind {

  logger::logger(const char* context)
  : log_(nullptr)
  {
    if (context)
      __create_logger(context);
  }

  logger::logger(string_t context)
  : log_(nullptr)
  {
    if (!context.empty())
      __create_logger(context.c_str());
  }

  logger::logger(const logger& src)
  {
    log_ = src.log_;
  }

  logger::~logger()
  {
    if (log_)
      delete log_;

    log_ = nullptr;
  }

  logger& logger::operator=(const logger& rhs)
  {
    if (this != &rhs) log_ = rhs.log_;

    return *this;
  }

  log4cpp::Category* logger::log() {
    return log_;
  }

  void logger::__create_logger(const char* context)
  {
    context_ = string_t(context);

    log_manager &mgr = log_manager::singleton();
    log_ = new log4cpp::FixedContextCategory(mgr.category(), context);
  }

  void logger::__destroy_logger() {
    if (log_)
      delete log_;

    log_ = nullptr;
  }

  log4cpp::CategoryStream logger::debug() { return log_->debugStream(); }
  log4cpp::CategoryStream logger::info() { return log_->infoStream(); }
  log4cpp::CategoryStream logger::notice() { return log_->noticeStream(); }
  log4cpp::CategoryStream logger::warn() { return log_->warnStream(); }
  log4cpp::CategoryStream logger::error() { return log_->errorStream(); }
  log4cpp::CategoryStream logger::alert() { return log_->alertStream(); }
  log4cpp::CategoryStream logger::crit() { return log_->critStream(); }
}
