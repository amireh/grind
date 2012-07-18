grind.define_view("dakwak", "errors", "system errors", 
  { "Timestamp", "FQDN", "Context", "Application", "Message" },
  function(fmt, ctx, entry)
    if entry.uuid then
      return false
    end
    
    return true, {
      Timestamp = entry.timestamp,
      FQDN = entry.fqdn,
      Context = entry.context,
      Application = entry.app,
      Message = entry.body
    }
  end)