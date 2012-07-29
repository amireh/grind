grind.define_view("pendulum", "battles", "workflow",
  { "Timestamp", "Battle", "Module", "Message" },
  function(fmt, ctx, entry)
    return true, { 
      Timestamp = entry.timestamp,
      Battle = entry.battle_id,
      Module = entry.module,
      Message = entry.body
    }
  end)