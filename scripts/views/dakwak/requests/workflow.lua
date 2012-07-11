grind.define_view("dakwak", "requests", "workflow", 
  { "Timestamp", "FQDN", "Context", "UUID", "Application", "Module", "Message" },
  function(ctx, entry)

    local out = {
      Timestamp = entry.meta.timestamp,
      FQDN = entry.meta.fqdn,
      Context = entry.meta.context,
      UUID = entry.meta.uuid,
      Application = entry.meta.app,
      Module = entry.meta.module,
      Message = entry.body
    }

    return true, out
  end)