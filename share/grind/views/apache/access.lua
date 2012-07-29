grind.define_view("apache2", "access logs", "all", 
  { "Timestamp", "Host", "HTTP", "Method", "RC", "UUID", "URL" },
  function(ctx, entry)
    local out = {
      Timestamp = entry.timestamp,
      Host = entry.host,
      HTTP = entry.http_version or "-",
      Method = entry.url and entry.method or "-",
      RC = entry.http_rc,
      UUID = entry.uuid,
      URL = entry.url and entry.url or entry.method
    }

    return true, out
  end)