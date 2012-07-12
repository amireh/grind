grind.define_view("apache2", "errors", "errors", 
  { "Timestamp", "Host", "Context", "Message" },
  function(ctx, entry)
    local out = {
      Timestamp = entry.meta.timestamp,
      Host = entry.meta.host,
      Context = entry.meta.context,
      Message = entry.meta.msg
    }

    return true, out
  end)