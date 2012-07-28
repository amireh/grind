local levels = {
  debug   = "[D]",
  info    = "[I]",
  notice  = "[N]",
  warn    = "[W]",
  error   = "[E]",
  crit    = "[C]",
  alert   = "[A]"
}

local ordered_levels = {
  "debug",
  "info",
  "notice",
  "warn",
  "error",
  "crit",
  "alert"
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

local enabled = function(in_level)
  for _,level in pairs(ordered_levels) do
    if level == grind.config.log_level then return true
    elseif level == in_level then return false end
  end
end

for level, token in pairs(levels) do
  if enabled(level) then
    logger[level] = function(self, msg)
      print( string.format("%s%s %s: %s%s", timestamp(), token, self.ctx, self.padding, msg) )
  
        return nil
    end
  else
    logger[level] = function() return nil end
  end
end

function logger:indent()
  self.padding = self.padding .. "  "
end
function logger:deindent()
  self.padding = self.padding:sub(0, #self.padding - 2)
end