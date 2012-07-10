grind.define_view("dakwak", "errors", "request errors", function(ctx, entry)
  if not entry.meta.uuid then
    return false
  end
  
  return true, {
    { "Timestamp", entry.meta.timestamp },
    { "FQDN", entry.meta.fqdn },
    { "Context", entry.meta.context },
    { "UUID", entry.meta.uuid },
    { "Application", entry.meta.app },
    { "Message", entry.body }
  }
end)