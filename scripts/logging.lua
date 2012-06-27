log_level = {
  debug = "[D]",
  info  = "[I]",
  notice = "[N]",
  warn  = "[W]",
  error = "[E]",
  crit = "[C]",
  alert = "[A]"
}

log = nil

log = function(m, l)
  print( (l or log_level.debug) .. " lua_grind: " .. m)

  return nil
end
