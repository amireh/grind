grind.define_group("grind", 11155)
grind.define_signature("grind", [[(?:(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2})\s(.*))+]])
grind.define_format("grind", "sessions", [==[(\[[A-Z]\]) (\w+): (.*)]==])
grind.define_extractor("grind", "sessions", { "context", "module", "body", "timestamp" })
grind.define_klass("grind", { "sessions" }, "sessions", function(fmt, entry)
  return true
end)
grind.define_view("grind", "sessions", "all",
  { "Timestamp", "Context", "Module", "Message" },
  function(fmt, ctx, entry)
    -- table.dump(entry, 0, grind.log)
    return true, { 
      Timestamp = entry.timestamp,
      Context = entry.context,
      Module = entry.module,
      Message = entry.body
    }
  end)