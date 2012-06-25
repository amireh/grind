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

#include "watcher.hpp"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/inotify.h>

#define EVENT_SIZE  ( sizeof (struct inotify_event) )
#define BUF_LEN     ( 1024 * ( EVENT_SIZE + 16 ) )

namespace grind {

  watcher::watcher(string_t const& fp)
  : logger(nullptr),
    fp_(fp),
    fd(-1),
    wd(-1)
  {
    logger::__create_logger(("watcher[" + fp_ + "]").c_str());
  }

  watcher::~watcher() {

  }

  void watcher::watch() {
    /*fd = inotify_init();

    if ( fd < 0 ) {
      perror( "inotify_init" );
    }

    wd = inotify_add_watch( fd, fp_.c_str(),
                           IN_MODIFY | IN_CREATE | IN_DELETE );

    info() << "watching " << fp_;

    // while (true) {
      int length, i = 0;
      char buffer[BUF_LEN];

      length = read( fd, buffer, BUF_LEN );

      if ( length < 0 ) {
        perror( "read" );
      }

      debug() << length << "bytes were read";

      while ( i < length ) {
        struct inotify_event *event = ( struct inotify_event * ) &buffer[ i ];

        debug() << "got an inotify event (mask = " << event->mask << ")";
        debug() << "evt length: " << event->len;

        // if ( event->len ) {
          if ( event->mask & IN_CREATE ) {
            if ( event->mask & IN_ISDIR ) {
              info() << "The directory " << event->name << " was created.";
            }
            else {
              info() << "The file " << event->name << " was created";
            }
          }
          else if ( event->mask & IN_DELETE ) {
            if ( event->mask & IN_ISDIR ) {
              info() << "The directory " << event->name << " was deleted";
            }
            else {
              info() << "The file " << event->name << " was deleted.";
            }
          }
          else if ( event->mask & IN_MODIFY ) {
            if ( event->mask & IN_ISDIR ) {
              info() << "The directory " << event->name << " was modified.";
            }
            else {
              info() << "The file " << event->name << " was modified.";
            }
          }
          else {
            warn() << "unknown event";
          }
        // } else {
        //   info() << "event has no length!";
        // }
        i += EVENT_SIZE + event->len;
      }
    // }
    */
  }

  void watcher::stop() {
    // info() << "stopping...";

    // ( void ) inotify_rm_watch( fd, wd );
    // ( void ) close( fd );

    // info() << "no longer watching";
  }
}
