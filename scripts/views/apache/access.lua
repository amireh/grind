grind.define_view("apache2", "access logs", "all", 
  { "Timestamp", "Host", "HTTP", "Method", "RC", "UUID", "URL" },
  function(ctx, entry)
    local out = {
      Timestamp = entry.meta.timestamp,
      Host = entry.meta.host,
      HTTP = entry.meta.http_version or "-",
      Method = entry.meta.url and entry.meta.method or "-",
      RC = entry.meta.http_rc,
      UUID = entry.meta.uuid,
      URL = entry.meta.url and entry.meta.url or entry.meta.method
    }

    return true, out
  end)