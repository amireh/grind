require 'rex_pcre'

local ptrn = [[(?<timestamp>[A-Z]{1}[a-z]{2} [0-9]+ [0-9]{2}:[0-9]{2}:[0-9]{2})\s{1}(?<app>\w+)\s{1}.*]]
local ptrn = [[(?:<\d+>)(?<timestamp>[A-Z]{1}[a-z]{2}\s+[0-9]+\s+[0-9]{2}:[0-9]{2}:[0-9]{2}\s{1})|(?<moo>\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s{1})|(\d{2}:\d{2}:\d{2}):\s{1}|(\d{2}:\d{2}:\d{2})]]
local ptrn = [[(?J)(?:<\d+>)(?<timestamp>[A-Z]{1}[a-z]{2}\s+[0-9]+\s+[0-9]{2}:[0-9]{2}:[0-9]{2}\s{1})?|(?<timestamp>\d{4}-\d{2}-\d{2}\s{1}\d{2}:\d{2}:\d{2}\s{1})?]]
local ptrn = [[(?|(?<DN>Mon|Fri|Sun)(?:day)?|(?<DN>Tue)(?:sday)?|(?<DN>Wed)(?:nesday)?|(?<DN>Thu)(?:rsday)?|(?<DN>Sat)(?:urday)?)]]
-- local ptrn = [[(?Jx)(Mon|Fri|Sun)(?:day)?|(Tue)(?:sday)?|(Wed)(?:nesday)?|(Thu)(?:rsday)?|(Sat)(?:urday)?]]
local ptrn = [[(foobar) went to the (?<place>\w+)]]
-- local ptrn = [[(foobar) went to the (?<place>\w+)]]
local text = [==[<15>Jun 27 20:45:19 cornholio dakapi: [I] {012345678} handler: looking up website with APIKey: 
1234-12-12 12:12:12 
]==]
local text = "foobar went to the zoo and foobared some more"

local rex = rex_pcre.new(ptrn)
if not rex then
  return print("Invalid PCRE rex '" .. ptrn .. "'")
end

local count = arg[1] or 10
print("Matching " .. ptrn .. " " .. count .. " times")

for i=0,count do
  print(rex:find(text))
  print(rex_pcre.match(text, rex))
  print(rex_pcre.find(text, rex))
  local b,e,captures = rex:exec(text)
  -- local e = nil
  print("Matched @ " .. b .. " => " .. e)
  local capture_values = {}
  local capture_b, capture_e = nil,nil
  for k,v in pairs(captures or {}) do
    if type(k) == "number" and type(v) == "number" then
      if not capture_b then capture_b = v
      elseif not capture_e then
        capture_e = v
        table.insert(capture_values, text:sub(capture_b, capture_e))
        capture_b, capture_e = nil, nil
      end
    end
    -- if type(k) ~= "number" and v then print(k .. " => " .. v) end
      -- e = v
    -- end
    -- if type(k) == "number" and v and type(v) == "string" then print(k .. " => " .. v) end
    -- print(k .. " => " .. tostring(v))
  end
  print("Captures:")
  for k,v in pairs(capture_values) do
    print(v)
  end
  -- rex:find(text)
end
