grind.define_klass("apache2", { "access" }, "access logs", function(entry)
  return entry.meta.url ~= nil
end)
