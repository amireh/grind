 -- syslog
-- grind.add_delimiter([[(?:<\d+>)([A-Z]{1}[a-z]{2}\s+[0-9]+\s+[0-9]{2}:[0-9]{2}:[0-9]{2}\s{1})]])
-- standalone log
-- grind.add_delimiter([[(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s{1})]])

grind.define_group("dakwak", 11142)
grind.define_delimiter("dakwak", [[(?:<\d+>)?([A-Z]{1}[a-z]{2}\s+[0-9]+\s+[0-9]{2}:[0-9]{2}:[0-9]{2}\s{1})]])
grind.define_delimiter("dakwak", [==[([\w|\.|-]+):(\d+)\s([\d|\.]+,\s[\d|\.]+)\s([A-Z]{1}-\w+)\s-\s-\s\[(\d{1,2}/\w{3}/\d{4}:\d{2}:\d{2}:\d{2}\s\+\d{4})\]]==])

grind.define_format("dakwak", "requests", [[(\w+) (\w+): (\[\w{1}\])(?: )?\s+?(?:{([\w|-]+)}\s+)?(?|([\S]+):\s+((?sm).*)|()(.*))]])
grind.define_extractor("dakwak", "requests",
  function(fqdn, app, context, uuid, module, content, timestamp)
    -- print("\tFQDN: " .. fqdn)
    -- print("\tApplication: " .. app)
    -- print("\tContext: " .. context)
    -- print("\tUUID: " .. tostring(uuid) )
    -- print("\tModule: " .. module)
    -- print("\tMessage: " .. content)

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

grind.define_format("dakwak", "apache", [["([A-Z]+)\s(.*)\s(?:HTTP/(\d\.\d))?"\s(\d{3})\s(\d+)\s"(.*)"\s"(.*)"]])
grind.define_extractor("dakwak", "apache",
  function(method, url, http_version, http_rc, id, referer, agent, vhost, port, fwd, uuid, timestamp)
    -- print("\tModule: " .. module)
    -- print("\tMessage: " .. content)
    -- local host, timestamp = nil, nil
    -- if timestamp_or_nothing then
    --   host = timestamp_or_host
    --   timestamp = timestamp_or_nothing
    -- else
    --   host = "unknown"
    --   timestamp = timestamp_or_host
    -- end

    return { 
      timestamp = timestamp,
      host = host,
      method = method,
      http_version = http_version,
      http_rc = http_rc,
      url = url,
      id = uuid,
      referer = referer,
      agent = agent,
      vhost = vhost,
      port = port,
      fwd = fwd,
      uuid = uuid
    }, ""
  end)


-- (?<=\{{1})([\w|-]+)(?=}{1})