grind.define_view("dakwak", "errors", "system errors", function(ctx, entry)
  if entry.meta.uuid then
    return false
  end
  
  return true, {
    { "Timestamp", entry.meta.timestamp },
    { "FQDN", entry.meta.fqdn },
    { "Context", entry.meta.context },
    { "Application", entry.meta.app },
    { "Message", entry.body }
  }
end)