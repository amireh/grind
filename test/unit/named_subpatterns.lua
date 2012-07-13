#!/usr/bin/env lua

require 'rex_pcre' -- luarocks install lrexlib-pcre

local ptrn = [[(?J)(?<DN>Mon|Fri|Sun)(?:day)?|(?<DN>Tue)(?:sday)?|(?<DN>Wed)(?:nesday)?|(?<DN>Thu)(?:rsday)?|(?<DN>Sat)(?:urday)?]]

local regex = regex_pcre.new(ptrn)
if not regex then
  return print("Invalid PCRE regex '" .. ptrn .. "'")
end

function test(subject)
  local _,__,captures = regex:exec(subject)
  print("Captures from '" .. subject .. "':")
  for k,v in pairs(captures or {}) do
    if type(k) ~= "number" and v then print("  " .. k .. " => " .. v) end
  end

  return test
end

test("Sunday")("Saturday")