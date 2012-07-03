require 'rex_pcre'
json = require 'dkjson'

grind = grind or { config = {}, paths = {} }

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

  grind.groups = {}

  require 'grind_cfg'
  require 'entry'
  require 'parser'

  log("Delimiter pattern: " .. grind.config.delimiter, log_level.info)

  for dir in ilist({ "groups", "views" }) do
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

        -- any views defined?
        for __,view in pairs(group.views) do
          if view.matcher(entry) then
            for ___,vgroup in pairs(view.groups) do
              local res, formatted_entry = vgroup.formatter(vgroup.context, entry)
              if res and formatted_entry then
                log("Committing an entry! : " .. tostring(json.encode(formatted_entry)))
                table.insert(entries, { 
                  group = group.label, 
                  view = view.label, 
                  view_group = vgroup.label,
                  entry = formatted_entry })
                vgroup.context = {}
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
    parsers = {},
    views = {}
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

-- grind.define_view():
--
-- Views contain a subset of the collective entries by defining
-- a general filter applied on the extracted entries. If the entry
-- passes the filteration, it will be passed on to the view's
-- groups for the final point of processing.
--
-- @param glabel the application group label
-- @param vlabel a unique label to identify this view (referenced by the view groups)
-- @param matcher a function that accepts the current entry and is expected
--                to return a boolean indicating whether the entry should be
--                passed on to the view groups or not
function grind.define_view(glabel, vlabel, matcher)
  local group = grind.groups[glabel]
  assert(group, "No application group called '" .. glabel .. "' is defined, can not define extractor!")

  grind.groups[glabel].views[vlabel] = { label = vlabel, matcher = matcher, groups = {} }
  log("  View defined: " .. glabel .. "[" .. vlabel .. "]")
end

-- grind.define_view_group():
--
-- A view group is meant to combine very specific entries to be presented
-- by the watcher interface as a group/listing.
--
-- @param glabel the application group label
-- @param vlabel the view label
-- @param vglabel a unique label to identify this view group
-- @param formatter a function that accepts the view group's context and the entry
--                  as arguments and is expected to return (at some point) a formatted version
--                  of the original entry to be committed.
--
-- @note the view group's context is reset everytime an entry is committed by that group
function grind.define_view_group(glabel, vlabel, vglabel, formatter)
  local group = grind.groups[glabel]
  assert(group, "No application group called '" .. glabel .. "' is defined, can not define extractor!")

  local view = group.views[vlabel]
  assert(view, 
    "No view called '" .. vlabel .. "' is defined for the application group " .. 
    glabel .. ", can not define view entry!")

  grind.groups[glabel].views[vlabel].groups[vglabel] = { label = vglabel, context = {}, formatter = formatter }

  log("    View group defined: " .. glabel .. "[" ..  vlabel .. "][" .. vglabel .. "]")
end