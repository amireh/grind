grind.define_view("elementum", "client", "battles", 
  { "Timestamp", "Context", "Module", "Message" },
  function(fmt, ctx, entry)

    local out = {
      Timestamp = entry.timestamp,
      Context = entry.context,
      Module = entry.module,
      Message = entry.body
    }

    return true, out
  end)