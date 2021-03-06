require 'rex_pcre'
-- json = require 'dkjson'
json = require 'cjson'

grind = grind or { 
  config = {}, 
  paths = {}, 
  groups = {}, 
  commands = {}, 
  watchers = {},
  keepers = {},
  subscriptions = {}
}

-- local logger, log = nil, nil
local log = nil

function grind.init(root)
  if grind.config.debug then
    local STP = require "StackTracePlus"
    debug.traceback = STP.stacktrace
  end
  
  grind.paths.root = root

  require 'logger'
  require 'helpers'

  -- logger = lua_grind.logger("grind")
  -- log = logger:log()
  log = logger:new("grind")

  log:info("Running from " .. root)

  grind.log = log
end

-- local leftovers = nil
-- local signature_rex = nil
-- function grind.leftovers() return leftovers end
function grind.start(kernel)
  log:info("starting...")

  grind.kernel = kernel
  -- configure the kernel
  do
    local option_set = function(ctx, option, in_type)
      return type(grind.config[ctx][option]) == in_type
    end
    -- the watcher listening interface
    if not option_set("kernel", "watcher_interface", "string") then
      return log:error("Watcher listening interface must be specified.")
    else
      kernel.cfg.watcher_interface = grind.config.kernel.watcher_interface
    end
    -- the watcher port
    if not option_set("kernel", "watcher_port", "string") then
      return log:error("No port specified for watcher connections.")
    else
      kernel.cfg.watcher_port = grind.config.kernel.watcher_port
    end

    if grind.config.log_level then
      kernel:set_logging_threshold( grind.config.log_level:sub(0,1):upper() )
    end
  end

  -- load the rest of the scripts
  load_script('api')
  load_script('entry')

  for dir in ilist(grind.config.entity_paths) do
    for filename in dirtree(dir) do
      if filename:find(".lua") and not filename:find("exclude") then
        load_script(filename)
      end
    end
  end

  return true
end


function grind.stop()
  log:info("Cleaning up")
  for _, group in pairs(grind.groups) do
    for __, klass in pairs(group.klasses) do
      klass.views = nil
    end
    group.klasses = nil
  end
  grind.groups = {}
  grind.commands = {}
  grind.subscriptions = {}
  grind.config = {}
end

function grind.handle(text, glabel)

  -- log("Handling '" .. text .. "' for " .. glabel)
  local group = grind.groups[glabel]
  assert(group)
  text = group.leftovers .. text
  local signature_rex = group.signature
  local b,e,c,b2,e2,c2 = 0,0,nil,0,0,nil
  local consumed = 0
  local has_keepers = #grind.keepers > 0
  while true do

    -- local signature_captures = { signature_rex:find(text,e) }
    -- b = signature_captures[1]
    -- e = signature_captures[2]
    b,e,c = signature_rex:find(text,e)
    b2,e2,c2 = signature_rex:find(text,e)

    if b == nil or b2 == nil then
    -- if b == nil then
      break
    end

    consumed = consumed + b2 - b
    -- consumed = consumed + e
    local signature_captures = { signature_rex:find(text:sub(b, b2 - 1)) }
    if #signature_captures > 0 then -- strip out the match boundaries
      table.remove(signature_captures,1)
      table.remove(signature_captures,1)
    end 

    local entry = entry_t:new(text:sub(e + 1, b2 - 1))
    -- local entry = entry_t:new(signature_captures[#signature_captures])
    local formats = {}
    for flabel, format in pairs(group.formats) do
      if format.nr_active_klasses > 0 or has_keepers  then
        local captures = format.matcher(entry.meta.raw)
        if #captures > 0 then
          table.insert(formats, { format, captures })
        end
      end
    end

    for format_and_captures in ilist(formats) do
      local format = format_and_captures[1]
      local captures = format_and_captures[2]

      log:debug("Group: " .. group.label .. ", applicable format: " .. format.label .. " on '" .. entry.meta.raw .. "'")
      
      -- append the signature format captures to the format captures
      for k,v in pairs(signature_captures) do 
        table.insert(captures, v)
      end

      -- get a hold on the entry structure
      -- local schema = group.extractors[format](unpack(captures))
      local schema = format.extractor(unpack(captures))

      -- assert(type(meta) == "table", "Group " .. group.label .. "'s extractor returned no message.meta table!")

      -- define the entry
      for k,v in pairs(schema) do 
        entry[k] = v
      end

      -- keep the raw version
      -- entry.meta.raw = nil

      -- see if any eligible klass is interested in the entry
      -- TODO: this can be optimized if we link klasses directly
      -- to the formats when they bind
      -- for __,klass in pairs(group.klasses) do
      local active_klasses =
        has_keepers and group.klasses or format.active_klasses

      -- for klabel,active_views in pairs(format.active_klasses) do
      for klabel,active_views_or_klass in pairs(active_klasses) do
        local klass = group.klasses[klabel]

        local active_views = 
          has_keepers and klass.views or active_views_or_klass

        -- if klass:belongs_to(format) and klass.matcher(format, entry, klass.context) then
        if klass.matcher(format.label, entry, klass.context) then
          log:indent()
          log:debug("Found an applicable klass: " .. klass.label)
          log:debug("Any Keeper attached? " .. tostring(has_keepers) .. ", #views: " .. #active_views)

          -- invoke the view formatters
          -- for ___,view in pairs(klass.views) do
          for _,view in pairs(active_views) do
            log:indent()
            log:debug("Looking for an application view")
            local do_commit, formatted_entry, keep_context = view.formatter(format.label, view.context, entry, klass.context)

            if do_commit and formatted_entry then

              local encoded_entry = json.encode({ 
                group = group.label, 
                klass = klass.label, 
                view = view.label,
                entry = formatted_entry
              })

              -- log:debug("Committing an entry! : " .. encoded_entry)

              -- broadcast to all subscribed watchers
              log:debug("looking for watchers subscribed to " ..
                        group.label .. ">>" .. klass.label .. ">>" .. view.label)

              for w_id,sub in pairs(grind.subscriptions) do
                if sub[1] == "*" or
                   (sub[1] == group.label and
                    sub[2] == klass.label and
                    sub[3] == view.label) then

                  local w = sub[4]
                  local do_relay = true

                  log:debug("Relaying to Watcher#" .. w:whois())

                  -- respect the subscription's filters, if any
                  for field, filter in pairs(sub.filters) do
                    local passed = true
                    
                    -- filter structure is: { is_regex_or_not, regex_or_string, is_negated_or_not }

                    -- a regex?
                    if filter[1] then
                      passed = rex_pcre.match(formatted_entry[field] or "", filter[2])
                    -- a literal comparison
                    else
                      passed = (formatted_entry[field] or "") == filter[2]
                    end

                    -- is it a negated filter?
                    if filter[3] then passed = not passed end

                    if not passed then
                      -- table.dump(formatted_entry)
                      log:debug("Filter on " .. field .. " => " .. tostring(filter[2]) ..
                                " failed, will not relay to " .. w:whois() .. 
                                " (" .. (formatted_entry[field] or "") .. ")")

                      do_relay = false
                      break
                    end
                  end -- view filters

                  if do_relay then
                    log:debug(encoded_entry)
                    w:send(encoded_entry)
                  end
                end -- the subscription is for this view
              end -- subscription loop

              -- reset the context
              if not keep_context then
                view.context = {}
              end
            end -- the view is comitting an entry

            log:deindent()
          end -- the view loop

          log:deindent()
        end -- the klass has matched
      end -- the klass loop
    end -- the format has matched
  end

  group.leftovers = text:sub(consumed)
  log:debug(consumed .. " bytes were consumed, and " .. #group.leftovers .. " bytes were left over.")
  -- print(leftovers)

  return nil
end

function grind.add_signature(pattern)
  table.insert(grind.config.signatures, pattern)
end

function grind.define_group(glabel, port, options)
  grind.groups = grind.groups or {}
  if grind.groups[glabel] then 
    log:notice("An application group called '" .. glabel .. "' is already defined, ignoring.")
    return true
  end

  -- port must not be occupied
  assert(grind.kernel:is_port_available(port), 
    "Port " .. port .. " is unavailable, can not assign " .. glabel .. " feeder. Aborting.")

  grind.kernel:register_feeder(glabel, port)

  -- was the binding successful?
  assert(grind.kernel:is_feeder_registered(glabel),
    "Feeder couldn't be registered for the application group " .. glabel .. "! AAborting.")

  grind.groups[glabel] = {
    label = glabel,
    port = port,
    initter = initter,
    __signature_patterns = {},
    signature = nil,
    -- formatters = {},
    -- extractors = {},
    formats = {},
    exclusive = false,
    klasses = {},
    leftovers = ""
  }

  if options then
    for k,v in pairs(options or {}) do grind.groups[glabel][k] = v end
  end

  log:debug("Application group defined: " .. glabel)
end

function grind.define_signature(glabel, ptrn)
  local group = grind.groups[glabel]
  assert(group, "No application group called '" .. glabel .. "' is defined, can not define extractor!")

  local rex = create_regex(ptrn)
  assert(rex, "Invalid signature '" .. ptrn .. "' for group '" .. glabel .. "'")

  table.insert(group.__signature_patterns, ptrn)
  if #group.__signature_patterns > 1 then
    group.signature = nil
    local expression = "(?|"
    -- local expression = "(?J)"
    for idx, signature in pairs(group.__signature_patterns) do
      expression = expression .. signature -- .. "?"
      if idx ~= #group.__signature_patterns then
        expression = expression .. "|"
      end
    end
    expression = expression .. ")"
    -- log:debug("Delimiter expression: " .. expression)
    group.signature = create_regex(expression)
  else
    group.signature = create_regex(ptrn)
  end

  assert(group.signature)

  log:info("Signature format defined for " .. glabel .. " => " .. (expression or ptrn) )
end; grind.define_delimiter = grind.define_signature

function grind.define_format(glabel, gformat, ptrn)
  local group = grind.groups[glabel]
  assert(group, "No application group called '" .. glabel .. "' is defined, can not define format!")

  assert(group.signature, "Application group " .. glabel .. " has no defined signature, can not continue.")

  -- for backwards compatibility, not assigning a gformat
  if not ptrn then ptrn, gformat = gformat, "default" end

  -- prepare the format capturer
  local rex = create_regex(ptrn)
  assert(rex, "Invalid formatter '" .. ptrn .. "' for group '" .. glabel .. "'")

  --[[
    format = { 
      matcher = regex,
      extractor = function,
      active_klasses = {
        [klass] = { active_views = { views } }
      }
    }
    when a subscription is made
  ]]

  log:info("Message format defined for " .. glabel .. ": " .. gformat .. " => " .. ptrn)
  group.formats[gformat] = {
    label = gformat,
    matcher = function(message_content)
      -- if this message does belong to us, return the
      -- captured parts that we'll be using later to parse it
      -- local capture = { rex_pcre.find(message_content, rex) }
      local capture = { rex:find(message_content) }
      if #capture > 0 then -- strip out the match boundaries
        table.remove(capture,1)
        table.remove(capture,1)
      end
      return capture
    end,
    extractor = nil,
    active_klasses = {},
    nr_active_klasses = 0
  }
end

-- define_extractor():
--
-- An extractor is a function exclusive to an application group
-- message format that defines the structure of entries for that
-- format. 
--
-- The structure is directly based on what's captured
-- from the format's regular expression written in grind.define_format()
-- above.
--
-- @param glabel the application group this extractor applies to
-- @param gformat the message format the extractor is for
-- @param extractor the extractor function or list, see below
--
-- If the extractor is specified as a list, ie:
--   { "timestamp", "context" }
-- then grind will internally define the fields [timestamp] and [context]
-- in the format entries which can be access using entry.timestamp, or
-- entry.context accordingly. 
--
-- However, if you need to customize or control the captures (for example,
-- converting a timestamp to epoch), you can define a function that will
-- receive a number of arguments equal to the number of subpatterns defined
-- in the @gformat expression. The function is expected to return a table of 
-- fields and their values to be merged with the entry.
--
-- Example extractor function:
--
-- function(timestamp, context) <--- if one wasn't captured, it will be set to false
--   return { timestamp = timestamp, context = context }
-- end
function grind.define_extractor(glabel, gformat, extractor)
  assert(typeof(glabel, "glabel", "string"))
  assert(typeof(gformat, "gformat", "string"))
  assert(typeof(extractor, "extractor", { "function", "table" }))

  local group = grind.groups[glabel]
  assert(group, "No application group called '" .. glabel .. "' is defined, can not define extractor!")

  -- if a list was provided instead of a function, then we'll
  -- define the extractor function for the user using the
  -- fields specified in the list
  if type(extractor) == "table" then
    local field_map = extractor
    extractor = function(...)
      local fields = arg
      local out = {}
      for i,field in pairs(field_map) do
        out[field] = fields[i]
      end
      return out
    end
  end

  -- grind.groups[glabel].extractors[gformat] = extractor
  grind.groups[glabel].formats[gformat].extractor = extractor
end

-- grind.define_klass():
--
-- Classes contain an arbitrarily categorizes subset of the application
-- group's entries. If an entry belongs to a klass (by being matched by
-- the klass's filters), it will be passed on to the klass views
-- for the final point of processing.
--
-- @param glabel the application group label
-- @param clabel a unique label to identify this klass (referenced by the views)
-- @param matcher a function that accepts the current entry and is expected
--                to return a boolean indicating whether the entry should be
--                passed on to the views or not
function grind.define_klass(glabel, gformats, clabel, matcher)
  assert(typeof(glabel, "glabel", "string"))
  assert(typeof(gformats, "gformats", "table"))
  assert(typeof(clabel, "clabel", "string"))
  assert(typeof(matcher, "matcher", "function"))

  local group = grind.groups[glabel]
  assert(group, "No application group called '" .. glabel .. "' is defined, can not define extractor!")

  if not matcher and type(gformats) == "string" then gformats = { gformats } end

  for format in ilist(gformats) do
    assert(group.formats[format], 
      "No format defined as " .. format .. " for the application group " .. glabel .. " in klass " .. ( clabel or "") )
  end

  local klass = { label = clabel, matcher = matcher, formats = gformats, views = {}, context = {} }
  group.klasses[clabel] = klass
  
  -- function klass:belongs_to(format)
  --   for f in ilist(self.formats) do if f == format then return true end end
  --   return false
  -- end

  log:info("  Class defined: " .. glabel .. "[" .. clabel .. "]")
end

-- grind.define_view():
--
-- A view is meant to combine very specific entries to be presented
-- by the watcher interface as a group/listing.
--
-- @param glabel the application group label
-- @param clabel the klass label
-- @param vlabel a unique label to identify this view
-- @param formatter a function that accepts the view's context and the entry
--                  as arguments and is expected to return (at some point) a formatted version
--                  of the original entry to be committed.
--
-- @note the view's context is reset everytime an entry is committed by that group
function grind.define_view(glabel, clabel, vlabel, skeleton, formatter)
  local group = grind.groups[glabel]
  assert(group, "No application group called '" .. glabel .. "' is defined, can not define extractor!")

  local klass = group.klasses[clabel]
  assert(klass, 
    "No klass called '" .. clabel .. "' is defined for the application group " .. 
    glabel .. ", can not define view!")

  grind.groups[glabel].klasses[clabel].views[vlabel] = { label = vlabel, skeleton = skeleton, context = {}, formatter = formatter }

  log:info("    View defined: " .. glabel .. "[" ..  clabel .. "][" .. vlabel .. "]")
end

--- grind.command():
---
--- Defines an API command.
--- 
--- @param name    the name of the command the handler is bound to
--- @param handler a method that accepts a table containing the command id and arguments
---                and is expected to return a result of any type
---
--- @note There can be only one handler for a certain command at any time.
function grind.command(name, handler)
  grind.commands[name] = handler
end

function grind.report_api_error(msg)
  return json.encode({
    success = false,
    message = msg
  })
end

function grind.handle_cmd(buf, watcher)
  local res = {}

  log:debug("Incoming command: " .. buf)

  local cmd = json.decode(buf)
  if not cmd or type(cmd) ~= "table" then
    log:error("Unable to decode command, aborting")
    return watcher:send( grind.report_api_error("Unable to decode command."))
  end

  if not cmd.id then
    log:error("Invalid command structure; missing id")
    return watcher:send( grind.report_api_error("Invalid command structure; missing 'id' field."))
  end

  log:debug("Command: " .. cmd.id )

  if not grind.commands[cmd.id] then
    log:error("Unsupported command " .. cmd.id)
    return watcher:send( grind.report_api_error("Unsupported command " .. cmd.id .. ".") )
  end

  -- table.dump(cmd)

  res, err = grind.commands[cmd.id](cmd, watcher)

  if not res then
    if err then
      return watcher:send( grind.report_api_error("Error: " .. err))
    end
    
    log:notice("Command " .. cmd.id .. " handling failed")
    return watcher:send( grind.report_api_error("Command " .. cmd.id .. " handling failed.") )
  end

  watcher:send(json.encode({ 
    command = cmd.id, 
    args = cmd.args or nil, 
    result = res
  }))

  return true
end

function grind.add_watcher(watcher)
  table.insert(grind.watchers, watcher)
  log:info("Watcher added: " .. watcher:whois())
  log:info("Watchers: " .. #grind.watchers)
end
function grind.remove_watcher(watcher)
  remove_by_cond(grind.watchers, function(_,w) return w:whois() == watcher:whois() end)
  local sub = grind.subscriptions[watcher:whois()]
  if sub and sub[1] == "*" then
    remove_by_cond(grind.keepers, function(_,k) return k:whois() == watcher:whois() end)
  elseif sub then
    repeat
    -- mark the subscription's view as inactive in the format
    --
    -- subscription structure:
    -- { group.label, klass.label, view.label, watcher, filters = {} }
    local group = grind.groups[sub[1]]
    if not group then
      log:error("Invalid subscription or something! Look at it: ")
      table.dump(sub)
      break
    end

    local klass = group.klasses[sub[2]]
    local view_label = sub[3]

    -- a klass can belong to many formats, so we have to handle them all
    for flabel in ilist(klass.formats) do
      local format = group.formats[flabel]
      -- remove the view from the list of active views for this klass
      remove_by_cond(format.active_klasses[klass.label],
        function(_,view) return view.label == view_label end)
      
      -- are there no other active views remaining?
      if #format.active_klasses[klass.label] == 0 then
        -- mark the klass as being inactive
        format.active_klasses[klass.label] = nil
        format.nr_active_klasses = format.nr_active_klasses - 1
      end

      if format.nr_active_klasses == 0 then
        log:notice("Format " .. format.label .. " is no longer active.")
      else
        log:notice("Format has " .. format.nr_active_klasses .. " active klasses remaining.")
      end
    end
    until true
  end

  sub = nil
  grind.subscriptions[watcher:whois()] = nil

  log:info("Watcher removed: " .. watcher:whois())
  log:info("Watchers: " .. #grind.watchers)
end