grind.define_view("dakwak", "apache", "access logs", 
  { "Timestamp", "VHost", "Port", "Forwarded-for", "UUID", "HTTP", "Method", "Referer", "Agent", "RC", "ID", "URL" },
  function(fmt, ctx, entry)
    print(type(entry))
    local out = {
      Timestamp = entry.timestamp,
      VHost = entry.vhost,
      Port = entry.port,
      ["Forwarded-for"] = entry.fwd,
      UUID = entry.uuid,
      Host = entry.host,
      HTTP = entry.http_version or "-",
      Method = entry.url and entry.method or "-",
      Referer = entry.referer,
      Agent = entry.agent,
      RC = entry.http_rc,
      ID = entry.id,
      URL = entry.url and entry.url or entry.method
    }

    return true, out
  end)