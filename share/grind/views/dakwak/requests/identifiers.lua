local extractors = {
  apikey = create_regex([[.*APIKey: (.*)]]),
  url = create_regex([[looking\sup\spage: (.*)]])
}

grind.define_view("dakwak", "requests", "identifiers", 
  { "uuid", "apikey", "url" },
  function(fmt, ctx, entry)

    if fmt == "apache" then
      return false
    end

    -- capture the APIKey
    local b,e,captured = nil,nil,nil
    
    if not ctx.apikey then
      b,e,captured_apikey = extractors.apikey:find(entry.body)
      if b ~= nil then
        ctx.apikey = captured_apikey
      end
    -- capture the URL
    elseif not ctx.url then
      b,e,captured_url = extractors.url:find(entry.body)
      if b ~= nil then
        ctx.url = captured_url
        ctx.uuid = entry.uuid
      end
    -- we're done, commit the entry
    else
      return true, {
        uuid = ctx.uuid,
        apikey = ctx.apikey,
        url = ctx.url
      }
    end

    return false, nil
  end)
