grind.define_view("dakwak", "errors", "all errors",
  { "Timestamp", "FQDN", "Context", "Type", "Application", "Message" },
  function(fmt, ctx, entry)
    return true, {
      Timestamp = entry.timestamp,
      FQDN = entry.fqdn,
      Context = entry.context,
      Type = entry.uuid and "Request" or "System",
      Application = entry.app,
      Message = entry.body
    }
  end)