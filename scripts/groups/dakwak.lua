 -- syslog
-- grind.add_delimiter([[(?:<\d+>)([A-Z]{1}[a-z]{2}\s+[0-9]+\s+[0-9]{2}:[0-9]{2}:[0-9]{2}\s{1})]])
-- standalone log
-- grind.add_delimiter([[(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s{1})]])

grind.define_group("dakwak", { exclusive = true })
grind.define_format("dakwak", [[(\w+) (\w+): (\[\w{1}\])(?: )?\s+?(?:{([\w|-]+)}\s+){0,1}([\S]+):\s+((?sm).*)]])
grind.define_extractor("dakwak", 
  function(fqdn, app, context, uuid, module, content, timestamp)
    print("\tFQDN: " .. fqdn)
    print("\tApplication: " .. app)
    print("\tContext: " .. context)
    print("\tUUID: " .. tostring(uuid) )
    print("\tModule: " .. module)
    print("\tMessage: " .. content)

    return { 
      timestamp = timestamp,
      fqdn = fqdn,
      app = app,
      context = context,
      uuid = uuid,
      module = module
    }, content
  end
)

-- (?<=\{{1})([\w|-]+)(?=}{1})