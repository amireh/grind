grind.define_group("dakwak", { exclusive = true })
grind.define_format("dakwak", "(\\w+) (\\w+): (\\[\\w{1}\\])(?: )?(\\s+{\\w+})?(\\s+[\\S]+): ((?sm).*)")
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

-- grind.map("dakwak", "default", function(entry)
-- end)
-- grind.map("dakwak", is_meta_set("uuid"), function(entry)
-- end)
-- -- grind.define_parser("dakwak", "dakapi", function(gctx, pctx, msg)
--   -- here you have msg.meta and msg.content ready for parsing!
-- -- end)

-- cornholio dakapi: [D] {012345678} connection: closed (elapsed: 7ms)