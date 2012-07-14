grind.define_view("dakwak", "requests", "workflow", 
  { "Timestamp", "FQDN", "Context", "UUID", "Application", "Module", "Message" },
  function(fmt, ctx, entry)
    local out = {}

    if fmt == "apache" then
      out = {
        Timestamp = entry.meta.timestamp,
        FQDN = "-",
        Context = "-",
        UUID = entry.meta.uuid,
        Application = "apache",
        Module = "-",
        Message = entry.meta.url
      }
    else
      out = {
        Timestamp = entry.meta.timestamp,
        FQDN = entry.meta.fqdn,
        Context = entry.meta.context,
        UUID = entry.meta.uuid,
        Application = entry.meta.app,
        Module = entry.meta.module,
        Message = entry.body
      }
    end

    return true, out
  end)