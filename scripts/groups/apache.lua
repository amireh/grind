-- grind.add_delimiter([==[(\d{2}:\d{2}:\d{2}):\s{1}]==])
grind.define_group("apache2", { exclusive = true })
grind.define_format("apache2", "access", [==["(?|([A-Z]{3,}) (.*) (?:HTTP\/(\d\.\d){1})|(.*))" (\d+) (.+)]==])
grind.define_extractor("apache2", "access",
  function(method, url, http_version, http_rc, uuid, timestamp_or_host, timestamp_or_nothing)
    -- print("\tModule: " .. module)
    -- print("\tMessage: " .. content)
    local host, timestamp = nil, nil
    if timestamp_or_nothing then
      host = timestamp_or_host
      timestamp = timestamp_or_nothing
    else
      host = "unknown"
      timestamp = timestamp_or_host
    end

    return { 
      timestamp = timestamp,
      host = host,
      method = method,
      http_version = http_version,
      http_rc = http_rc,
      url = url,
      uuid = uuid
    }, ""
  end
)

grind.define_format("apache2", "errors", [==[(?|\[(\w+)\]\s(?:\[client ([^\]]+)\]?)?(.*)|(.*))]==])
grind.define_extractor("apache2", "errors",
  function(context_or_msg, in_host, in_msg, timestamp)
    local ctx, host, msg = "N/A", "unknown", ""
    print(context_or_msg)
    print(in_host)
    print(in_msg)
    print(timestamp)

    -- has no context and no host, only a message
    if not in_msg then
      msg = context_or_msg

    -- has 2 of them, a context and a message
    elseif not in_host then
      ctx = context_or_msg
      msg = msg
    -- has all 3; context, then a host, then a msg
    else
      ctx = context_or_msg
      host = in_host
      msg = in_msg
    end

    return { 
      timestamp = timestamp,
      context = ctx,
      host = host,
      msg = msg
    }, ""
  end
)