require 'helpers'

parser = {}

function parser:new(label)
  local o = {}
  setmetatable(o, { __index = self })
  o.__index = self

  o.label = label

  return o
end

function parser:consume(entry)
  -- extract the context

  -- extract the fqdn

  return true
end
