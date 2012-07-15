require 'rex_pcre'
json = require 'dkjson'

grind = grind or { 
  config = {}, 
  paths = {}, 
  groups = {}, 
  commands = {}, 
  watchers = {},
  subscriptions = {}
}

function set_paths(root)
  package.path = "?.lua;" .. package.path -- for absolute paths
  package.path = root .. "/../?.lua;" .. package.path -- for relative paths
  package.path = root .. "/?.lua;" .. package.path
  package.cpath = "/usr/local/lib/?.so;" .. package.cpath

  local STP = require "StackTracePlus"
  debug.traceback = STP.stacktrace
  
  grind.paths.root = root

  require 'helpers'
  require 'logging'
  require "lua_grind"
end

-- local leftovers = nil
-- local signature_rex = nil
-- function grind.leftovers() return leftovers end
function grind.start(kernel)
  log("starting...", log_level.info)

  grind.kernel = kernel

  load_script('grind_cfg')
  load_script('api')
  load_script('entry')

  -- for group,port in pairs(grind.config.groups or {}) do
  --   kernel:register_feeder(group, port)
  -- end

  log("Delimiter patterns: ", log_level.info)
  for signature in ilist(grind.config.signatures) do
    log("  " .. signature, log_level.info)
  end

  for dir in ilist({ "groups", "klasses", "views" }) do
    for filename in dirtree(grind.paths.root .. '/' .. dir) do
      if filename:find(".lua") and not filename:find("exclude") then
        load_script(filename)
      end
    end
  end

  -- leftovers = ""
  -- local expression = "(?|"
  -- -- local expression = "(?J)"
  -- for idx, signature in pairs(grind.config.signatures) do
  --   expression = expression .. signature-- .. "?"
  --   if idx ~= #grind.config.signatures then
  --     expression = expression .. "|"
  --   end
  -- end
  -- expression = expression .. ")"
  -- log("Delimiter expression: " .. expression)
  -- signature_rex = create_regex(expression)
  -- if not signature_rex then
  --   assert(false)
  -- end

end


function grind.stop()
  log("Cleaning up", log_level.info)
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

local show_two_times = 2

function grind.handle(text, glabel)

  -- log("Handling '" .. text .. "' for " .. glabel)
  local group = grind.groups[glabel]
  assert(group)
  text = group.leftovers .. text
  local signature_rex = group.signature
  local entries = {}
  b,e,c,b2,e2,c2 = 0,0,nil,0,0,nil
  consumed = 0
  while true do

    b,e,c = signature_rex:find(text,e)
    b2,e2,c2 = signature_rex:find(text,e)

    if b == nil or b2 == nil then
      break
    end

    consumed = consumed + b2 - b
    -- local entry = entry_t:new(c, text:sub(e + 1, b2 - 1))
    local signature_captures = { rex_pcre.find(text:sub(b, b2 - 1), signature_rex) }
    if #signature_captures > 0 then -- strip out the match boundaries
      table.remove(signature_captures,1)
      table.remove(signature_captures,1)
    end    

    local entry = entry_t:new(nil, text:sub(e + 1, b2 - 1))

    -- for _,group in pairs(grind.groups) do
      log("Checking if group " .. group.label .. " is applicable for '" .. entry.meta.raw .. "'...")


      -- local captures = group.formatter(entry.meta.raw)
      local captures = {}
      local format = nil
      for _format, formatter in pairs(group.formatters) do
        -- local raw = entry.meta.raw
        -- log("checking if format " .. _format .. " is compatible on: " .. entry.meta.raw)
        captures = formatter(entry.meta.raw)
        -- print(raw)
        if #captures > 0 then
          format = _format
          break
        end
      end

      if format then
        log("Found an applicable group: " .. group.label .. " using format " .. format .. " for '" .. entry.meta.raw .. "'")
        -- local meta, body = group.extractor(entry.meta.timestamp, unpack(captures))
        for k,v in pairs(signature_captures) do table.insert(captures, v) end
        local meta, body = group.extractors[format](unpack(captures))

        assert(type(meta) == "table", "Group " .. group.label .. "'s extractor returned no message.meta table!")
        assert(type(body) == "string", "Group " .. group.label .. "'s extractor returned no message.body string!")

        for k,v in pairs(meta) do entry.meta[k] = v end
        entry.body = body
        -- entry.meta.raw = nil

        -- any klasses defined?
        for __,klass in pairs(group.klasses) do
          if klass:belongs_to(format) and klass.matcher(format, entry, klass.context) then
            log("  Found an applicable klass: " .. klass.label)
            for ___,view in pairs(klass.views) do
              local res, formatted_entry, keep_context = view.formatter(format, view.context, entry, klass.context)
              if res and formatted_entry then

                local encoded_entry = json.encode({ 
                  group = group.label, 
                  klass = klass.label, 
                  view = view.label,
                  entry = formatted_entry
                })

                -- log("Committing an entry! : " .. encoded_entry)

                -- broadcast to all subscribed watchers
                log("looking for watchers subscribed to "..
                    group.label .. ">>" .. klass.label .. ">>" .. view.label)
                for w_id,s in pairs(grind.subscriptions) do
                  if s[1] == "*" or
                     (s[1] == group.label and
                     s[2] == klass.label and
                     s[3] == view.label)
                  then
                    local w = s[4]
                    local do_relay = true
                    log("Relaying to Watcher#" .. w:whois())
                    if s.filters then
                      for field, match in pairs(s.filters) do
                        local match_res = true
                        if match[1] then -- a regex
                          match_res = rex_pcre.match(formatted_entry[field] or "", match[2])
                        else
                          match_res = (formatted_entry[field] or "") == match[2]
                        end

                        -- is it a negated filter?
                        if match[3] then match_res = not match_res end

                        if not match_res then
                          table.dump(formatted_entry)
                          log("Filter on " .. field .. " => " .. tostring(match[2]) ..
                           " failed, will not relay to " .. w:whois() .. " (" .. (formatted_entry[field] or "") .. ")")
                          do_relay = false
                          break
                        end
                      end -- view filters
                    end -- if any filters are defined

                    if do_relay then
                      w:send(encoded_entry)
                    end
                  end -- the subscription is for this view
                end -- subscription loop

                -- reset the context
                if not keep_context then
                  view.context = {}
                end
              end -- the view is comitting an entry
            end -- the view loop
          end -- the klass has matched
        end -- the klass loop

        -- if group.exclusive then
        --   log("Group is exclusive, will discard entry now.")
        --   break
        -- end

      end -- the format has matched

    -- end
  end

  group.leftovers = text:sub(consumed)
  print(consumed .. " bytes were consumed, and " .. #group.leftovers .. " bytes were left over.")
  -- print(leftovers)

  return nil
end

function grind.add_signature(pattern)
  table.insert(grind.config.signatures, pattern)
end

function grind.define_group(glabel, port, options)
  grind.groups = grind.groups or {}
  if grind.groups[glabel] then 
    log("An application group called '" .. glabel .. "' is already defined, ignoring.", log_level.notice)
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
    formatters = {},
    extractors = {},
    exclusive = false,
    klasses = {},
    leftovers = ""
  }

  if options then
    for k,v in pairs(options or {}) do grind.groups[glabel][k] = v end
  end

  log("Application group defined: " .. glabel)
end

function grind.define_signature(glabel, ptrn)
  local group = grind.groups[glabel]
  assert(group, "No application group called '" .. glabel .. "' is defined, can not define extractor!")

  local rex = create_regex(ptrn)
  assert(rex, "Invalid signature '" .. ptrn .. "' for group '" .. glabel .. "'")

  table.insert(group.__signature_patterns, ptrn)
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
  log("Delimiter expression: " .. expression)
  group.signature = create_regex(expression)
  assert(group.signature)

  log("Application group signature defined: " .. expression)
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

  log("Formatter defined for " .. glabel .. ": " .. gformat .. " => " .. ptrn)
  group.formatters[gformat] = function(message_content)
    -- if this message does belong to us, return the
    -- captured parts that we'll be using later to parse it
    local capture = { rex_pcre.find(message_content, rex) }
    if #capture > 0 then -- strip out the match boundaries
      table.remove(capture,1)
      table.remove(capture,1)
    end
    return capture
  end
end

-- define_extractor():
--
-- An extractor is a function exclusive to an application group
-- that locates and defines the metadata (if any) and the content
-- from the raw entry. 
--
-- @param glabel the application group this extractor applies to
-- @param extractor the extractor function, see below
--
-- The extractor's arguments:
--   1. the message's timestamp
--   2. the subpatterns captured by the group capturer in define_group()
--
-- Two values are expected to be returned:
--   1. a table to be used as the message's meta
--   2. the message content
function grind.define_extractor(glabel, gformat, extractor)
  local group = grind.groups[glabel]
  assert(group, "No application group called '" .. glabel .. "' is defined, can not define extractor!")

  -- for backwards compatibility, not assigning a gformat
  if not extractor then extractor, gformat = gformat, "default" end

  grind.groups[glabel].extractors[gformat] = extractor
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
  -- for backwards compatibility, not assigning a gformat
  if not matcher then matcher, clabel, gformats = clabel, gformats, { "default" } end


  for format in ilist(gformats) do
    assert(group.formatters[format], 
      "No format defined as " .. format .. " for the application group " .. glabel .. " in klass " .. ( clabel or "") )
  end

  local klass = { label = clabel, matcher = matcher, formats = gformats, views = {}, context = {} }
  group.klasses[clabel] = klass
  
  function klass:belongs_to(format)
    for f in ilist(self.formats) do if f == format then return true end end
    return false
  end

  log("  Class defined: " .. glabel .. "[" .. clabel .. "]")
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

  log("    View defined: " .. glabel .. "[" ..  clabel .. "][" .. vlabel .. "]")
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

  log("Incoming command: " .. buf)

  local cmd = json.decode(buf)
  if not cmd then
    log("Unable to decode command, aborting", log_level.error)
    return watcher:send( grind.report_api_error("Unable to decode command."))
  end

  if not cmd.id then
    log("Invalid command structure; missing id", log_level.error)
    return watcher:send( grind.report_api_error("Invalid command structure; missing 'id' field."))
  end

  log("Command: " .. cmd.id )

  if not grind.commands[cmd.id] then
    log("Unsupported command " .. cmd.id, log_level.error)
    return watcher:send( grind.report_api_error("Unsupported command " .. cmd.id .. ".") )
  end

  -- table.dump(cmd)

  res, err = grind.commands[cmd.id](cmd, watcher)

  if not res then
    if err then
      return watcher:send( grind.report_api_error("Error: " .. err))
    end
    
    log("Command " .. cmd.id .. " handling failed", log_level.notice)
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
  log("Watcher added: " .. watcher:whois())
  log("Watchers: " .. #grind.watchers)
end
function grind.remove_watcher(watcher)
  remove_by_cond(grind.watchers, function(_,w) return w:whois() == watcher:whois() end)
  grind.subscriptions[watcher:whois()] = nil
  log("Watcher removed: " .. watcher:whois())
  log("Watchers: " .. #grind.watchers)
end



function error_test(foo, bar)
  print("HELLO THERE: " .. foo .. bar)
  -- return "yarr", "moo"
  return moo()
end
function moo()
  print("HEY")
  return zeeee()
end
function zeeee()
  error("Fuck this shit")
end

-- if not debug then debug = {} end
-- debug.traceback = function(_, __) print("oi") end
