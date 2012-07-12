grind.define_klass("dakwak", "requests", "errors", function(entry)
  local ctx = entry.meta.context
  return ctx ~= "[D]" and ctx ~= "[I]"
end)
