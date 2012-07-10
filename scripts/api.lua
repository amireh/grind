grind.command("list_groups", function(cmd)
  local res = {}
  for _, group in pairs(grind.groups) do
    local entry = { 
      label = group.label, 
      klasses = {}
    }

    for __, klass in pairs(group.klasses) do
      local klass_entry = { label = klass.label, views = {} }

      for ___, view in pairs(klass.views) do
        table.insert(klass_entry.views, view.label)
      end

      table.insert(entry.klasses, klass_entry)
    end

    table.insert(res, entry)
  end

  return res
end)

grind.command("query_group", function(cmd)
  local res = {}

  -- validate arguments
  if not cmd.args then
    return false, "Missing 1 required arguments, args.group"
  elseif not cmd.args.group then
    return false, "Missing argument: args.group"
  end

  local group = grind.groups[cmd.args.group]
  if not group then 
    log("No such application group '" .. cmd.args.group .. "'.", log_level.error)
    return false, "No such application group '" .. cmd.args.group .. "'"
  end

  for _, klass in pairs(group.klasses) do
    table.insert(res, klass.label)
  end

  return res
end)

grind.command("query_klass", function(cmd)
  local res = {}

  -- validate arguments
  if not cmd.args then
    return false, "Missing 2 required arguments, args.group and args.klass"
  elseif not cmd.args.group then
    return false, "Missing argument: args.group"
  elseif not cmd.args.klass then
    return false, "Missing argument: args.klass"
  end

  local group = grind.groups[cmd.args.group]
  if not group then 
    log("No such application group '" .. cmd.args.group .. "'.", log_level.error)
    return false, "No such application group '" .. cmd.args.group .. "'"
  end

  local klass = group.klasses[cmd.args.klass]
  if not klass then 
    log("No such klass '" .. cmd.args.klass .. "'.", log_level.error)
    return false, "No such klass '" .. cmd.args.klass .. "'"
  end

  for _, view in pairs(klass.views) do
    table.insert(res, view.label)
  end

  return res
end)