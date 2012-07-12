local extractor = create_regex([[Bad element attribute line: '(.*)' for element (.*) in (.*)]])

grind.define_view("OGRE", "errors", "bad attributes", 
  { "Timestamp", "Element", "Container", "Cause" },
  function(ctx, entry, kctx)

    if kctx.error_type ~= "bad_attribute" then
      return false
    end

    local b,e, cause, el, container = rex_pcre.find(entry.body, extractor)

    local out = {
      Timestamp = entry.meta.timestamp,
      Element = el,
      Container = container,
      Cause = cause
    }

    return true, out
  end)