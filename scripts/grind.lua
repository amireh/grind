require 'rex_pcre'

function set_paths(root)
  print("setting path to " .. root)
  package.path = root .. "/?.lua;" .. package.path
  require 'helpers'
end

grind = grind or {}

grind.start = function()
  print("starting...")
end

local leftovers = ""
local ptrn = "([A-Z]{1}[a-z]{2} [0-9]+ [0-9]{2}:[0-9]{2}:[0-9]{2} )+"
local rex = rex_pcre.new(ptrn)
if not rex then
  return print("Invalid PCRE rex '" .. ptrn .. "'")
end

grind.handle = function(text)
  print("Handling '" .. text .. "'")

  text = leftovers .. text
  entries = {}
  b,e,c,b2,e2,c2 = 0,0,nil,0,0,nil
  consumed = 0
  while true do
    b,e,c = rex:find(text,e)
    b2,e2,c2 = rex:find(text,e)

    if not b or not b2 then
      break
    else
      -- print(b .. ", " .. e .. " => " .. c .. "[" .. text:sub(e+1,b2-2) .. "]")
      consumed = consumed + b2 - b
      table.insert(entries, { c, text:sub(e+1,b2-2) })
    end
  end

  print(consumed .. " bytes were consumed")
  leftovers = text:sub(consumed)
  print(#leftovers .. " bytes were left over: '" .. leftovers .. "'")

  for k,v in pairs(entries) do
    print(k)
    print("\t" .. v[1])
    print("\t" .. v[2])
  end

end
