require 'lfs'
require 'rex_pcre'
require 'logging'

-- Locates the function identified by @name and passes it
-- the arguments. This is used by the C/C++ wrapper.
function arbitrator(name, ...)
  -- construct the method pointer
  local _p = _G
  for word in list_iter(split_mcd(name, '.')) do
    _p = _p[word]
    if not _p then
      return error("attempting to call an invalid arbitrary method: " .. name)
    end
  end
  return _p(unpack(arg))
end

-- List iterator.
function list_iter(t)
  local i = 0
  local n = table.getn(t)
  return function ()
    i = i + 1
    if i <= n then return t[i] else return nil end
  end
end

ilist = list_iter -- alias

-- Reverse list iterator.
function rlist_iter(t)
  local n = table.getn(t)
  local i = n+1
  return function ()
    i = i - 1
    if i > 0 then return t[i] else return nil end
  end
end

-- Splits a string by the delimiter @pat.
-- Returns a table of all the delimited parts.
function split(str, pat, nr_occurences, keep_last)
  local t = {}  -- NOTE: use {n = 0} in Lua-5.0
  local fpat = "(.-)" .. pat
  local last_end = 1
  local s, e, cap = str:find(fpat, 1)
  local curr_count = 0
  while s do
    if nr_occurences and nr_occurences <= curr_count then break end

    if s ~= 1 or cap ~= "" then
      table.insert(t,cap)
    end
    curr_count = curr_count + 1
    last_end = e+1
    s, e, cap = str:find(fpat, last_end)
  end

  if last_end <= #str and (not nr_occurences or keep_last) then
    cap = str:sub(last_end)
    table.insert(t, cap)
  end

  return t
end

-- A multi-char delimiter string splitting routine.
-- Credit goes to Nick Gammon @ http://www.gammon.com.au/forum/?id=6079
function split_mcd(s, delim)
  assert (type (delim) == "string" and string.len (delim) > 0,
          "bad delimiter")

  local start = 1
  local t = {}  -- results table

  -- find each instance of a string followed by the delimiter
  while true do
    local pos = string.find (s, delim, start, true) -- plain find

    if not pos then
      break
    end

    table.insert (t, string.sub (s, start, pos - 1))
    start = pos + string.len (delim)
  end -- while

  -- insert final one (after last delimiter)
  table.insert (t, string.sub (s, start))

  return t
end -- function split

function all_words(str)
  local t = {}
  local b = 0
  local e = 0
  b,e = str:find("%w+", e+1)
  while b do
    table.insert(t, str:sub(b,e))
    b,e = str:find("%w+", e+1)
  end
  return t
end

function capitalize(str)
  if not str then return nil end
  return (str:gsub("^%l", string.upper))
end

function find_by_key(t, key)
  for k,v in pairs(t) do
    if k == key then return v end
  end
  return nil
end

function find_by_cond(in_table, functor)
  for item in list_iter(in_table) do
    if functor(item) then return item end
  end

  return nil
end
-- alias
find_by_condition = find_by_cond

function find_by_value(in_table, in_val)
  return find_by_cond(in_table, function(item) if item == in_val then return true end end)
end

function remove_by_value(inTable, inValue)
  local i = 1
  for val in list_iter(inTable) do
    if val == inValue then
      table.remove(inTable, i)
      break
    end
    i = i+1
  end
end
function remove_by_cond(in_table, functor)
  i = 1
  for k,v in pairs(in_table) do
    if functor(k,v) then table.remove(in_table, i); break; end
    i = i + 1
  end

end

-- trim whitespace from both ends of string
function trim(s)
  return s:find'^%s*$' and '' or s:match'^%s*(.*%S)'
end

-- trim whitespace from left end of string
function triml(s)
  return s:match'^%s*(.*)'
end

-- trim whitespace from right end of string
function trimr(s)
  return s:find'^%s*$' and '' or s:match'^(.*%S)'
end

function table.contains(table, item)
  return find_by_value(table, item) ~= nil
end

function table.dump(t, indent)
  if not indent then indent = 0 end
  local padding = ""
  for i=0,indent do padding = padding .. "  " end
  -- print("Dumping table " .. tostring(t) .. " which has " .. #t .. " elements")
  for k,v in pairs(t) do
    if type(v) == "table" then 
      table.dump(v, indent + 1)
    else
      print(padding .. tostring(k) .. " => " .. tostring(v))
    end
  end
end

-- Extends a table to include a contains() member method that returns whether
-- the table has a certain value.
--
-- Usage: my_table:contains(some_key)
-- Example:
--  my_table = searchable({ "foo", "bar" }) -> { "foo", "bar" }
--  my_table:contains("foo")                -> true
function searchable(t)
  function t:contains(item) return table.contains(t, item) end
  return t
end

function report_mem_usage()
  local mem = gcinfo("count")
  print("-- Memory used: " .. mem .. "KB")
end

function dirtree(dir)
  assert(dir and dir ~= "", "directory parameter is missing or empty")
  if string.sub(dir, -1) == "/" then
    dir=string.sub(dir, 1, -2)
  end

  local function yieldtree(dir)
    for entry in lfs.dir(dir) do
      if entry ~= "." and entry ~= ".." then
        entry=dir.."/"..entry
        local attr=lfs.attributes(entry)
        coroutine.yield(entry,attr)
        if attr.mode == "directory" then
          yieldtree(entry)
        end
      end
    end
  end

  return coroutine.wrap(function() yieldtree(dir) end)
end

function create_regex(ptrn)
  local regex = rex_pcre.new(ptrn)
  if not regex then
    return log("Invalid PCRE regex pattern '" .. ptrn .. "'", log_level.error)
  end

  -- test the pattern just in case there's a capture error
  local str = "test_string"
  local res, msg = pcall( rex_pcre.gsub, str, regex, "foobar" )
  if not res then
    return log( "Invalid PCRE regex '" .. ptrn .."'. Cause: " .. msg, log_level.error)
  end

  return regex
end

function load_script(script)
  script = script:gsub(".lua", "")
  package.loaded[script] = nil
  return require(script)
end
