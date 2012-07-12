local extractor = create_regex([==[(?:Compiler error: )(.*) in (.*)\((\d+)\)(?:: (.*))*]==])

grind.define_view("OGRE", "errors", "compiler errors", 
  { "Timestamp", "File", "Line", "Type", "Cause" },
  function(ctx, entry, kctx)

    if kctx.error_type ~= "compiler" then
      return false
    end

    local b,e, err_type, file, line, cause = rex_pcre.find(entry.body, extractor)

    if not cause then cause = err_type; err_type = "N/A" end

    local out = {
      Timestamp = entry.meta.timestamp,
      File = file,
      Line = line,
      Type = err_type or "N/A",
      Cause = cause
    }

    return true, out
  end)