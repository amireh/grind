grind.define_view("dakwak", "apache", "access logs", 
  { "Timestamp", "VHost", "Port", "Forwarded-for", "UUID", "HTTP", "Method", "Referer", "Agent", "RC", "ID", "URL" },
  function(fmt, ctx, entry)
    print(type(entry))
    local out = {
      Timestamp = entry.meta.timestamp,
      VHost = entry.meta.vhost,
      Port = entry.meta.port,
      ["Forwarded-for"] = entry.meta.fwd,
      UUID = entry.meta.uuid,
      Host = entry.meta.host,
      HTTP = entry.meta.http_version or "-",
      Method = entry.meta.url and entry.meta.method or "-",
      Referer = entry.meta.referer,
      Agent = entry.meta.agent,
      RC = entry.meta.http_rc,
      ID = entry.meta.id,
      URL = entry.meta.url and entry.meta.url or entry.meta.method
    }

    return true, out
  end)