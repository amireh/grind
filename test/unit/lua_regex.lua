require 'rex_pcre'

local ptrn = "([A-Z]{1}[a-z]{2} [0-9]+ [0-9]{2}:[0-9]{2}:[0-9]{2} )+"
local text = [==[
Jun 25 12:31:44 cornholio dakapi: [I] Channel[translations]: closing1
Jun 25 12:31:46 cornholio dakapi: [I] Channel[translations]: closing2
Jun 25 12:31:48 cornholio dakapi: [I] Channel[translations]: closing3
Jun 25 12:31:50 cornholio dakapi: [I] Channel[translations]: closing4
Jun 25 12:31:52 cornholio dakapi: [I] Channel[translations]: closing5
]==]

local rex = rex_pcre.new(ptrn)
if not rex then
  return print("Invalid PCRE rex '" .. ptrn .. "'")
end

local count = arg[1] or 10
print("Matching " .. ptrn .. " " .. count .. " times")

for i=0,count do
  rex:find(text)
  rex:find(text)
end
