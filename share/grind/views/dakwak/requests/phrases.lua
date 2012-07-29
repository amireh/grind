local extractors = {
  -- phrase_and_xpath = create_regex([[Queuing phrase for translation: '(.*)' \((.*)\)]]),
  phrase = create_regex([[registering term (.*)]]),
  skipped = create_regex([[skipping duplicate term (.*)|filter applied]]),
  digest = create_regex([[looking up term \(digest\((.*)\)\)]]),
  trans = create_regex([[translation found: ObjectId\("(.*)"\)|no translation was found, going to proxy it]]),
  translated = create_regex([[a translation (was) found|(no) translation was found]]),
  linked = create_regex([[term (is) already linked|term is (not) linked]])
}

local create_entry = function(ctx)
  local out = {
    UUID =   ctx.uuid,
    Phrase = ctx.phrase,
    Digest = ctx.digest,
    Translation = ctx.trans,
    Linked = ctx.linked,
    Status = ctx.status
  }
  return out
end

grind.define_view("dakwak", "requests", "phrases", 
  { "UUID", "Phrase", "Digest", "Translation", "Linked", "Status" },
  function(fmt, ctx, entry)
    -- we know the messages we need only come from this app, so there's
    -- no need to waste regex tests on other entries
    if fmt ~= "requests" or
       entry.app ~= "dakapi" or
       not (entry.module:match("handler") or
            entry.module:match("db_manager")) then
      return false
    end

    -- check if the term has been skipped for duplication,
    -- then no other field will be specified so we commit immediately
    if ctx.phrase and not ctx.checked_for_skipping then
      local b,e,skipped = extractors.skipped:find(entry.content)
      if b ~= nil then
        if skipped then
          ctx.digest = skipped
          ctx.status = "Skipped"
        else
          ctx.status = "Filtered"
        end
        return true, create_entry(ctx)
      end
      ctx.checked_for_skipping = true
    end

    -- capture the phrase
    if not ctx.phrase then
      local b,e,phrase = extractors.phrase:find(entry.content)
      if b ~= nil then
        ctx.phrase = phrase
        ctx.uuid = entry.uuid
      end
    elseif not ctx.digest then
      local b,e,digest = extractors.digest:find(entry.content)
      if b ~= nil then
        ctx.digest = digest
      end
    elseif not ctx.trans then
      local b,e,id = extractors.trans:find(entry.content)
      if b ~= nil then
        ctx.trans = id
      end
    elseif not ctx.translated then
      local b,e,translated_or_not = extractors.translated:find(entry.content)
      if b ~= nil then
        ctx.status = translated_or_not == "was" and "Translated" or "Proxied"
        ctx.translated = true
      end
    elseif not ctx.linked then
      local b,e,linked_or_not = extractors.linked:find(entry.content)
      if b ~= nil then
        ctx.linked = linked_or_not == "is" and "Yes" or "No"

        -- we're done, commit the entry
        ctx.done = true
      end
    end

    if ctx.done then
      return true, create_entry(ctx)
    end

    return false
  end)
