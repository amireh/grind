grind.define_view("apache2", "errors", "errors", 
  { "Timestamp", "Host", "Context", "Message" },
  function(ctx, entry)
    local out = {
      Timestamp = entry.timestamp,
      Host = entry.host,
      Context = entry.context,
      Message = entry.msg
    }

    return true, out
  end)