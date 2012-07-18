grind.define_view("dakwak", "requests", "workflow", 
  { "Timestamp", "FQDN", "Context", "UUID", "Application", "Module", "Message" },
  function(fmt, ctx, entry)
    local out = {}

    if fmt == "apache" then
      out = {
        Timestamp = entry.timestamp,
        UUID = entry.uuid,
        Application = "apache",
        Message = entry.url
      }
    else
      out = {
        Timestamp = entry.timestamp,
        FQDN = entry.fqdn,
        Context = entry.context,
        UUID = entry.uuid,
        Application = entry.app,
        Module = entry.module,
        Message = entry.body
      }
    end

    return true, out
  end)