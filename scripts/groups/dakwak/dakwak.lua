grind.define_group("dakwak", { exclusive = true })
grind.define_format("dakwak", [[(\w+) (\w+): (\[\w{1}\])(?: )?\s+{([\w|-]+)}?\s+([\S]+):\s+((?sm).*)]])
grind.define_extractor("dakwak", 
  function(timestamp, fqdn, app, context, uuid, module, content)
    print("\tFQDN: " .. fqdn)
    print("\tApplication: " .. app)
    print("\tContext: " .. context)
    print("\tUUID: " .. tostring(uuid) )
    print("\tModule: " .. module)
    print("\tMessage: " .. content)

    return { 
      fqdn = fqdn,
      app = app,
      context = context,
      uuid = uuid,
      module = module
    }, content
  end
)