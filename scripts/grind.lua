require 'rex_pcre'
json = require 'json'

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

  for dir in ilist({ "groups", "groups/parsers" }) do
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
  -- print("Handling '" .. text .. "'")

  text = leftovers .. text
  local entries = {}
  b,e,c,b2,e2,c2 = 0,0,nil,0,0,nil
  consumed = 0
  while true do
    b,e,c = delimiter_rex:find(text,e)
    b2,e2,c2 = delimiter_rex:find(text,e)

    if not b or not b2 then
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
        entry.content = content

        table.insert(entries, entry)

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
    parsers = {}
  }

  if options then
    for k,v in pairs(options) do grind.groups[glabel][k] = v end
  end
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

--[[
define_extractor():
  This method needs to define the metadata (if any) and the content
  from the raw message. 

  Arguments:
    1. the application group this extractor applies to
    2. the actual extractor method

  The extractor's arguments:
    1. the message's timestamp
    2. the subpatterns captured by the group capturer in define_group()

  Two values are expected to be returned:
    1) a table to be used as the message's meta
    2) the message content
]]
function grind.define_extractor(glabel, extractor)
  local group = grind.groups[glabel]
  assert(group, "No application group called '" .. glabel .. "' is defined, can not define extractor!")

  grind.groups[glabel].extractor = extractor
end