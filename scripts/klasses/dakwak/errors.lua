grind.define_klass("dakwak", { "requests" }, "errors", function(fmt, entry)
  local ctx = entry.meta.context
  print("Context: " .. ctx)
  return ctx ~= "[D]" and ctx ~= "[I]"
end)
