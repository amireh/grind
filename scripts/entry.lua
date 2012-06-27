require 'helpers'

entry_t = {}

function entry_t:new(timestamp, raw)
  local o = {}
  -- setmetatable(o, { __index = self })
  -- o.__index = self

  o.meta = {
    timestamp = timestamp,
    raw = raw
  }

  return o
end
