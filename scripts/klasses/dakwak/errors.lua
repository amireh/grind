grind.define_klass("dakwak", "errors", function(entry)
  local ctx = entry.meta.context
  return ctx ~= "[D]" and ctx ~= "[I]"
end)
