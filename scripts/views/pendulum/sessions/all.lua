grind.define_view("pendulum", "sessions", "all",
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