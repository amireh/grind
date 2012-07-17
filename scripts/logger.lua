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
  o.padding = ""

  return o
end

local timestamp = function()
  return os.date("%m-%d-%Y %H-%M-%S ")
end

for level, token in pairs(levels) do
  logger[level] = function(self, msg)
    print( string.format("%s%s %s: %s%s", timestamp(), token, self.ctx, self.padding, msg) )

    return nil
  end
end

function logger:indent()
  self.padding = self.padding .. "  "
end
function logger:deindent()
  self.padding = self.padding:sub(0, #self.padding - 2)
end