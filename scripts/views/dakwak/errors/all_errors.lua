grind.define_view("dakwak", "errors", "all errors",
  { "Timestamp", "FQDN", "Context", "Type", "Application", "Message" },
  function(fmt, ctx, entry)
    return true, {
      Timestamp = entry.meta.timestamp,
      FQDN = entry.meta.fqdn,
      Context = entry.meta.context,
      Type = entry.meta.uuid and "Request" or "System",
      Application = entry.meta.app,
      Message = entry.body
    }
  end)