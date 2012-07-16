grind.define_group("pendulum", 11151)
grind.define_signature("pendulum", [[(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2})]])

grind.define_format("pendulum", "sessions", [==[(\[[A-Z]\]) (\w+): (.*)]==])
grind.define_extractor("pendulum", "sessions", 
  { "context", "module", "body", "timestamp" })
  -- function(context, module, body, timestamp)
  --   return {
  --     timestamp = timestamp,
  --     context = context,
  --     module = module,
  --   }, body
  -- end)

grind.define_format("pendulum", "battles", [==[(\[[A-Z]\])\s(?|{(.*)}\s|)(\w+):\s(.*)]==])
grind.define_extractor("pendulum", "battles", 
  { "context", "battle_id", "module", "body", "timestamp" })
  -- function(context, battle_id, module, body, timestamp)
  --   return {
  --     timestamp = timestamp,
  --     context = context,
  --     battle_id = battle_id,
  --     module = module
  --   }, body
  -- end)