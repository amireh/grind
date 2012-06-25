require 'rex_pcre'

local ptrn = "([A-Z]{1}[a-z]{2} [0-9]+ [0-9]{2}:[0-9]{2}:[0-9]{2} )+"
local text = [==[
Jun 25 12:31:44 cornholio dakapi: [I] Channel[translations]: closing1
Jun 25 12:31:46 cornholio dakapi: [I] Channel[translations]: closing2
Jun 25 12:31:48 cornholio dakapi: [I] Channel[translations]: closing3
Jun 25 12:31:50 cornholio dakapi: [I] Channel[translations]: closing4
Jun 25 12:31:52 cornholio dakapi: [I] Channel[translations]: closing5
Jun 25 12:31:54 foo
]==]

local rex = rex_pcre.new(ptrn)
if not rex then
  return print("Invalid PCRE rex '" .. ptrn .. "'")
end

-- i = 0
print(#text)
entries = {}
-- for i=0,10000 do
  b,e,c,b2,e2,c2 = 0,0,nil,0,0,nil
  consumed = 0
  while true do
    b,e,c = rex:find(text,e)
    b2,e2,c2 = rex:find(text,e)

    if not b or not b2 then
      break
    else
      print(b .. ", " .. e .. " => " .. c .. "[" .. text:sub(e+1,b2-2) .. "]")
      consumed = consumed + b2 - b
      table.insert(entries, { c, text:sub(e+1,b2-2) })
    end

    -- i = i + 1

    -- if i == 10 then break end
  end
  print(consumed)
  package.path = "../../scripts/?.lua;" .. package.path
  require 'helpers'
  for k,v in pairs(entries) do
    print(k)
    print("\t" .. v[1])
    print("\t" .. v[2])
  end
-- end
-- print(rex:find(text))

-- for token in rex_pcre.split(text, rex) do
--   print(i .. " => " .. "'" .. token .. "'")
--   i = i + 1
-- end

rex = nil
ptrn = nil
text = nil
