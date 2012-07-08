require 'rex_pcre'
json = require 'dkjson'

grind = grind or { config = {}, paths = {}, groups = {}, commands = {} }

function set_paths(root)
  package.path = "?.lua;" .. package.path -- for absolute paths
  package.path = root .. "/../?.lua;" .. package.path -- for relative paths
  package.path = root .. "/?.lua;" .. package.path

  grind.paths.root = root

  require 'helpers'
  require 'logging'
end

local leftovers = nil
local delimiter_rex = nil

function grind.start()
  log("starting...", log_level.info)

  -- grind.groups = {}

  require 'grind_cfg'
  require 'api'
  require 'entry'

  log("Delimiter pattern: " .. grind.config.delimiter, log_level.info)

  for dir in ilist({ "groups", "klasses", "views" }) do
    for filename in dirtree(grind.paths.root .. '/' .. dir) do
      if filename:find(".lua") then
        load_script(filename)
      end
    end
  end

  leftovers = ""
  delimiter_rex = create_regex(grind.config.delimiter)
  if not delimiter_rex then
    assert(false)
  end
end


function grind.stop()
  log("Cleaning up", log_level.info)
end

function grind.handle(text)
  log("Handling '" .. text .. "'")

  text = leftovers .. text
  local entries = {}
  b,e,c,b2,e2,c2 = 0,0,nil,0,0,nil
  consumed = 0
  while true do
    b,e,c = delimiter_rex:find(text,e)
    b2,e2,c2 = delimiter_rex:find(text,e)

    if b == nil or b2 == nil then
      break
    end

    consumed = consumed + b2 - b
    local entry = entry_t:new(c, text:sub(e + 1, b2 - 1))

    for _,group in pairs(grind.groups) do
      log("Checking if group " .. group.label .. " is applicable...")

      local captures = group.formatter(entry.meta.raw)
      if #captures > 0 then
        log("Found an applicable group: " .. group.label)
        local meta, body = group.extractor(entry.meta.timestamp, unpack(captures))

        assert(type(meta) == "table", "Group " .. group.label .. "'s extractor returned no message.meta table!")
        assert(type(body) == "string", "Group " .. group.label .. "'s extractor returned no message.body string!")

        for k,v in pairs(meta) do entry.meta[k] = v end
        entry.body = body
        entry.meta.raw = nil

        -- any klasses defined?
        for __,klass in pairs(group.klasses) do
          if klass.matcher(entry) then
            for ___,view in pairs(klass.views) do
              local res, formatted_entry, order_sensitive = view.formatter(view.context, entry)
              if res and formatted_entry then
                log("Committing an entry! : " .. tostring(json.encode(formatted_entry)))
                table.insert(entries, { 
                  group = group.label, 
                  klass = klass.label, 
                  view = view.label,
                  entry = formatted_entry })
                view.context = {}
              end
            end
          end
        end

        if group.exclusive then
          log("Group is exclusive, will discard entry now.")
          break
        end
      end -- #captures > 0

    end
  end

  leftovers = text:sub(consumed)
  print(consumed .. " bytes were consumed, and " .. #leftovers .. " bytes were left over.")

  -- for k,entry in pairs(entries) do
  --   print(k .. " " .. entry.meta.timestamp .. " " .. entry.content)
  -- end

  return json.encode(entries)
end

function grind.define_group(glabel, options)
  grind.groups = grind.groups or {}
  if grind.groups[glabel] then 
    log("An application group called '" .. glabel .. "' is already defined, ignoring.", log_level.notice)
    return true
  end

  grind.groups[glabel] = {
    label = glabel,
    initter = initter,
    formatter = nil,
    extractor = nil,
    exclusive = false,
    klasses = {}
  }

  if options then
    for k,v in pairs(options) do grind.groups[glabel][k] = v end
  end

  log("Application group defined: " .. glabel)
end

function grind.define_format(glabel, ptrn)
  local group = grind.groups[glabel]
  assert(group, "No application group called '" .. glabel .. "' is defined, can not define format!")

  -- prepare the format capturer
  local rex = create_regex(ptrn)
  assert(rex, "Invalid formatter '" .. ptrn .. "' for group '" .. glabel .. "'")

  log("Formatter defined for " .. glabel .. " => " .. ptrn)
  function group.formatter(message_content)
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
function grind.define_extractor(glabel, extractor)
  local group = grind.groups[glabel]
  assert(group, "No application group called '" .. glabel .. "' is defined, can not define extractor!")

  grind.groups[glabel].extractor = extractor
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
function grind.define_klass(glabel, clabel, matcher)
  local group = grind.groups[glabel]
  assert(group, "No application group called '" .. glabel .. "' is defined, can not define extractor!")

  grind.groups[glabel].klasses[clabel] = { label = clabel, matcher = matcher, views = {} }
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
function grind.define_view(glabel, clabel, vlabel, formatter)
  local group = grind.groups[glabel]
  assert(group, "No application group called '" .. glabel .. "' is defined, can not define extractor!")

  local klass = group.klasses[clabel]
  assert(klass, 
    "No klass called '" .. clabel .. "' is defined for the application group " .. 
    glabel .. ", can not define view!")

  grind.groups[glabel].klasses[clabel].views[vlabel] = { label = vlabel, context = {}, formatter = formatter }

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

function grind.handle_cmd(buf)
  local res = {}

  local cmd = json.decode(buf)
  if not cmd then
    log("Unable to decode command, aborting", log_level.error)
    return grind.report_api_error("Unable to decode command.")
  end

  if not cmd.id then
    log("Invalid command structure; missing id", log_level.error)
    return grind.report_api_error("Invalid command structure; missing 'id' field.")
  end

  log("Command: " .. cmd.id )

  if not grind.commands[cmd.id] then
    log("Unsupported command " .. cmd.id, log_level.error)
    return grind.report_api_error("Unsupported command " .. cmd.id .. ".")
  end

  table.dump(cmd)

  res, err = grind.commands[cmd.id](cmd)

  if not res then
    if err then
      return grind.report_api_error("Error: " .. err)
    end
    
    log("Command " .. cmd.id .. " handling failed", log_level.notice)
    return grind.report_api_error("Command " .. cmd.id .. " handling failed.")
  end

  return json.encode({ 
    command = cmd.id, 
    args = cmd.args or nil, 
    result = res
  })
end
