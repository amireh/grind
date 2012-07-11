local extractors = {
  apikey = create_regex([[.*APIKey: (.*)]]),
  url = create_regex([[looking\sup\spage: (.*)]])
}


grind.define_view("dakwak", "requests", "workflow", 
  { "Timestamp", "FQDN", "Context", "UUID", "Application", "Message" },
  function(ctx, entry)
    -- local out = entry:clone()

    -- out:add("Timestamp", entry.meta.timestamp)
    -- out:add("FQDN", entry.meta.fqdn)
    -- out:add("Context", entry.meta.context)
    -- out:add("UUID", entry.meta.uuid)
    -- out:add("Application", entry.meta.app)
    -- out:add("Message", entry.body)

    -- table.dump(out)

    local out = {
      { "Timestamp", entry.meta.timestamp },
      { "FQDN", entry.meta.fqdn },
      { "Context", entry.meta.context },
      { "UUID", entry.meta.uuid },
      { "Application", entry.meta.app },
      { "Message", entry.body }
    }

    return true, out
  end)