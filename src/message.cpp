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

#include "message.hpp"
#include "utility.hpp"

namespace grind {

  using utility::stringify;

  const char* message::footer = "\n";
  const uint32_t message::max_length = 65563;
  const string_t message::null_property_ = "";

	message::message() {
    reset();
  }

  message::message(const message_uid in_uid, const message_feedback fdbck, unsigned char flags)
  : uid(in_uid),
    uid_length(in_uid.size()),
    options(flags),
    feedback(fdbck),
    length(0),
    checksum(0),
    rawsz(0),
    any(0)
  {
		properties.clear();
	}

	message::~message()
  {
  }

	void message::reset() {
    uid = "Unidentified Message";
    uid_length = uid.size();
    options = 0;
		feedback = message_feedback::unassigned;
    length = 0;
    checksum = 0;
    rawsz = 0;
    any = 0;
    if (!properties.empty())
      properties.clear();
	}

	message::message(const message& src) {
		_clone(src);
	}

	message& message::operator=(const message& rhs) {
		if (this != &rhs)
			_clone(rhs);

		return *this;
	}

	void message::_clone(const message& src) {
		reset();

    this->uid = src.uid;
		this->uid_length = src.uid.size();
    this->options = src.options;
		this->feedback = src.feedback;
    this->length = src.length;
    this->rawsz = src.rawsz;
    this->checksum = src.checksum;
    this->any = src.any;

    if (!src.properties.empty())
      for (property_t::const_iterator property = src.properties.begin();
           property != src.properties.end();
           ++property)
        set_property(property->first, property->second);
	}

	void message::set_property(const string_t inName, const string_t inValue) {
		if ( has_property(inName) ) {
			properties.find(inName)->second = inValue;
			return;
		}

		properties.insert( std::make_pair(inName, inValue) );
	}

	void message::set_property(const string_t inName, int inValue) {
		if ( has_property(inName) ) {
			properties.find(inName)->second = stringify(inValue);
			return;
		}

		properties.insert( std::make_pair(inName, stringify(inValue)) );
	}

	string_t const& message::property(const string_t inName) const {
		return properties.find(inName)->second;
	}

  bool message::has_property(const string_t inName) const {
    return (properties.find(inName) != properties.end());
  }

  bool message::has_option(unsigned char opt) const {
		return (this->options & opt) == opt;
	}

	void message::dump(std::ostream& inStream) const {
		inStream
      << "uid: " << uid << "\n"
      << "unformatted? " << ((options & message::no_format) == message::no_format ? "yes" : "no")
      << "\n"
      << "feedback: " << (feedback == message_feedback::error ? "error" : "ok")
        << "(" << (int)feedback << ")" << "\n"
      << "length: " << length << "\n"
      << "CRC: " << checksum << "\n"
      << "properties count: " << properties.size() << "\n";

		inStream << "properties: \n";
    for (property_t::const_iterator property = this->properties.begin();
         property != this->properties.end();
         ++property)
			inStream << "\t" << property->first << " : " << property->second << "\n";

	}

  int message::_CRC32(const string_t& my_string) {
    boost::crc_32_type result;
    result.process_bytes(my_string.data(), my_string.size());
    return result.checksum();
  }

  bool message::from_stream(boost::asio::streambuf& in) {

    size_t bytes_received = in.size();
    if (bytes_received < message::header_length + message::footer_length -2 /* debug */) {
      std::cerr
        << "Message is too short (" << bytes_received
        << " out of " << message::header_length + message::footer_length << ')';
      return false;
    }

    string_t uid;
    unsigned char feedback, flags;
    uint32_t uid_length, length;

    std::istream is(&in);
    is.unsetf(std::ios_base::skipws);
    is >> uid_length;
    for (uint32_t i = 0; i < uid_length; ++i)
      uid.push_back(is.get());
    is >> flags >> feedback >> length;
    is.get();

    // this->uid = (message_uid)uid;
    this->uid = uid;
    this->options = flags;
    this->feedback = (message_feedback)feedback;
    this->length = length;

    // check header's sanity
    if (//(this->uid <= message_uid::unassigned || this->uid >= message_uid::sanity_check) ||
        (this->length > message::max_length) ||
        (this->feedback >= message_feedback::sanity_check))
    {
      std::cerr
        << "Message failed header sanity check! [" << this->uid_length << "-" << this->uid << ',' << this->length << ',' << (int)this->feedback << "]";
      return false;
    }

    // there must be N+sizeof(int) bytes of properties where N > in_bytes - signature
    if (this->length > 0 && (bytes_received - message::header_length - message::footer_length < this->length+sizeof(int))) {
      std::cerr << "Message has invalid properties length: " << this->length;
      return false;
    }

    // parse properties
    if (this->length > 0) {

      int checksum;
      is >> checksum;
      is.get();

      string_t props;
      for (size_t i=0; i < this->length; ++i)
        props.push_back(is.get());

      // verify CRC checksum
      this->checksum = message::_CRC32(props);
      if (this->checksum != checksum) {
        std::cerr << "Message CRC mismatch, aborting: " << this->checksum << " vs " << checksum << " for " << props << " => " << props.size();
        return false;
      }

      // an unformatted message?
      if ((this->options & message::no_format) == message::no_format) {
        this->set_property("Data", string_t(props));
      }
      else {
        std::vector<string_t> elems = utility::split(props, ',');
        if( !(elems.size() > 0 && elems.size() % 2 == 0) ) {
          std::cerr << "Message has an invalid property pair length: " << elems.size();
          return false;
        }

        for (unsigned int i=0; i < elems.size(); i+=2)
          this->set_property(elems[i], elems[i+1]);
      }

      //delete props;
    }

    // skip the footer
    in.consume(message::footer_length);
    // this->dump();

    return true;
  }

  void message::to_stream(boost::asio::streambuf& out) const {

    //std::cout << "pre-message dump: buffer has " << out.size() << "(expected 0), ";
    std::ostream stream(&out);

    string_t props = "";
    if (!this->properties.empty()) {
      // if the event is raw, we've to dump only one property
      if ((this->options & message::no_format) == message::no_format) {
        // must have this, otherwise discard
        assert(this->has_property("Data"));
        if (this->has_property("Data"))
          props = this->property("Data");
      } else {
        // flatten properties
        property_t::const_iterator property;
        for (property = this->properties.begin();
             property != this->properties.end();
             ++property)
          props += property->first + "," + property->second + ",";

        props.erase(props.end()-1);
      }
    }

    stream << (uint32_t)this->uid.size();
    stream << this->uid;
    stream << (unsigned char)this->options;
    stream << (unsigned char)this->feedback;
    //stream.rdbuf()->sputn(stringify((uint16_t)props.size()).c_str(), 2);
    stream << (uint32_t)props.size() << " ";
    if (!props.empty()) {

      stream << message::_CRC32(props) << " ";
      stream << props;
    }

    stream << message::footer;
  }

  string_t message::_uid_to_string(message_uid uid) {
    string_t suid = "";
    /*switch (uid) {
      case message_uid::unassigned: suid = "unassigned"; break;
      case message_uid::sanity_check: suid = "sanity_check"; break;
      default:
        suid = "Unknown msg!!";
    }*/
    // return suid;
    return uid;
  }

  std::ostream& operator<<(std::ostream& inStream, const message& msg)
  {
    inStream << message::_uid_to_string(msg.uid);
    return inStream;
  }

  std::string const& message::operator[](std::string const& key) const
  {
    if (!has_property(key))
      return null_property_;

    return property(key);
  }

}
