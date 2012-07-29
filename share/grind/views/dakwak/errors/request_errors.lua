grind.define_view("dakwak", "errors", "request errors", 
  { "Timestamp", "FQDN", "Context", "UUID", "Application", "Message" },
  function(fmt, ctx, entry)
    if not entry.uuid then
      return false
    end
    
    return true, {
      Timestamp = entry.timestamp,
      FQDN = entry.fqdn,
      Context = entry.context,
      UUID = entry.uuid,
      Application = entry.app,
      Message = entry.body
    }
  end)