local extractors = {
  behemoth = create_regex([==[behemoth defined: (\w+)\[(\d+)\]]==]),
  monkey = create_regex([==[event: create_monkey, args: \[ color: (.*), id: (\d+), owner: (\d+) \]]==])
}

local behemoths = {}

grind.define_view("pendulum", "battles", "monkeys",
  { "Battle", "Owner", "Monkey ID", "Color" },
  function(fmt, ctx, entry)
    
    -- for easy access
    local battle = entry.battle_id

    -- is it a behemoth?
    local _,_,behemoth,id = extractors.behemoth:find(entry.body)
    if behemoth then
      -- track it so we can use its name when it creates a monkey:

      -- since behemoths are unique only in one battle, we must store them
      -- inside another collection identified by the battle id      
      if not behemoths[battle] then
        behemoths[battle] = {}
      end

      behemoths[battle][id] = behemoth .. "[" .. id .. "]"

      return false -- nothing else to do with this entry
    end

    -- is it a monkey?
    local _,_,name,id,owner = extractors.monkey:find(entry.body)
    if name then
      return true, { 
        Battle = entry.battle_id,
        Owner = behemoths[battle][owner], -- look up the behemoth we tracked earlier
        ["Monkey ID"] = id, -- we must surround the key by [""] since it has a space
        Color = name
      }      
    end

    return false -- ok, it's neither a behemoth nor a monkey, return nothing!
  end)