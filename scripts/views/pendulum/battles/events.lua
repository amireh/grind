local evt_extractor = create_regex([==[event: ([\w|_]+), args: \[ (.*) \]]==])

grind.define_view("pendulum", "battles", "events",
  { "Battle", "Event", "Arguments" },
  function(fmt, ctx, entry)
    local b,e,event,args = evt_extractor:find(entry.body)
    if b ~= nil then
      return true, { 
        Battle = entry.meta.battle_id,
        Event = event,
        Arguments = args
      }      
    end
  end)