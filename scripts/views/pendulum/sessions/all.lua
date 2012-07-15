grind.define_view("pendulum", "sessions", "all",
  { "Timestamp", "Context", "Module", "Message" },
  function(fmt, ctx, entry)
    return true, { 
      Timestamp = entry.meta.timestamp,
      Context = entry.meta.context,
      Module = entry.meta.module,
      Message = entry.body
    }
  end)