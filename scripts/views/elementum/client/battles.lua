grind.define_view("elementum", "client", "battles", 
  { "Timestamp", "Context", "Module", "Message" },
  function(ctx, entry)

    local out = {
      Timestamp = entry.meta.timestamp,
      Context = entry.meta.context,
      Module = entry.meta.module,
      Message = entry.body
    }

    return true, out
  end)