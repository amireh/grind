local levels = {
  debug = "[D]",
  info  = "[I]",
  notice = "[N]",
  warn  = "[W]",
  error = "[E]",
  crit = "[C]",
  alert = "[A]"
}

logger = {}

function logger:new(ctx, obj)
  local o = {} or obj
  setmetatable(o, { __index = self })
  self.__index = self
  o.ctx = ctx

  return o
end

local timestamp = function()
  return os.date("%m-%d-%Y %H-%M-%S ")
end

for level, token in pairs(levels) do
  logger[level] = function(self, msg)
    print( timestamp() .. token .. " " .. self.ctx .. ": " .. msg)

    return nil
  end
end