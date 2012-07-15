grind.define_view("pendulum", "battles", "workflow",
  { "Timestamp", "Battle", "Module", "Message" },
  function(fmt, ctx, entry)
    return true, { 
      Timestamp = entry.meta.timestamp,
      Battle = entry.meta.battle_id,
      Module = entry.meta.module,
      Message = entry.body
    }
  end)