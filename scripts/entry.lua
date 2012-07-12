require 'helpers'

entry_t = {}

function entry_t:new(c, raw)
  local o = {}
  -- setmetatable(o, { __index = self })
  -- o.__index = self
  o.meta = {
    raw = raw
  }
  -- print(type(c))

  -- local b,e,captures = capturer:exec(raw)
  -- for k,v in pairs(captures or {}) do
  --   if type(k) ~= "number" and v then 
  --     print("** adding to meta: " .. k .. " => " .. v)
  --     o.meta[k] = v
  --   end
  -- end

  return o
end
