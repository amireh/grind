local extractors = {
  hero = create_regex([==[hero defined: (\w+)\[(\d+)\]]==]),
  unit = create_regex([==[event: create_unit, args: \[ name: (.*), id: (\d+), owner: (\d+) \]]==])
}

local heroes = {}

grind.define_view("pendulum", "battles", "units",
  { "Battle", "Owner", "Unit ID", "Name" },
  function(fmt, ctx, entry)
    
    local battle = entry.meta.battle_id

    -- is it a hero?
    local b,e,hero,id = extractors.hero:find(entry.body)
    if b ~= nil then
      -- just track it so we can use its name when it creates a unit
      if not heroes[battle] then
        heroes[battle] = {}
      end

      heroes[battle][id] = hero .. "[" .. id .. "]"
      return true, { 
        Battle = entry.meta.battle_id, 
        ["Unit ID"] = id, 
        Name = hero
      }
    end

    -- is it a unit?
    local b,e,name,id,owner = extractors.unit:find(entry.body)
    if b ~= nil then
      return true, { 
        Battle = entry.meta.battle_id,
        Owner = heroes[battle][owner],
        ["Unit ID"] = id,
        Name = name
      }      
    end
  end)