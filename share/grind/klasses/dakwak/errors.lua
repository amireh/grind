grind.define_klass("dakwak", { "requests" }, "errors", function(fmt, entry)
  local ctx = entry.meta.context
  return ctx ~= "[D]" and ctx ~= "[I]"
end)
