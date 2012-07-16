%module lua_grind
%{
  #include <string>
  typedef std::string string_t;
%}

typedef std::string string_t;

%include "std_string.i"
%include "std_vector.i"

%include "kernel.i"
%include "connection.i"
