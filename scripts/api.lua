local log = logger:new("API")

grind.command("group_ports", function(cmd)
  local res = {}
  for _, group in pairs(grind.groups) do
    res[group.label] = group.port
  end

  return res
end)

grind.command("list_groups", function(cmd)
  local res = {}
  for _, group in pairs(grind.groups) do
    local entry = { 
      label = group.label,
      port = group.port,
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
    log:error("No such application group '" .. cmd.args.group .. "'.")
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
    log:error("No such application group '" .. cmd.args.group .. "'.")
    return false, "No such application group '" .. cmd.args.group .. "'"
  end

  local klass = group.klasses[cmd.args.klass]
  if not klass then 
    log:error("No such klass '" .. cmd.args.klass .. "'.")
    return false, "No such klass '" .. cmd.args.klass .. "'"
  end

  for _, view in pairs(klass.views) do
    table.insert(res, view.label)
  end

  return res
end)


grind.command("query_view", function(cmd, watcher)
  -- validate arguments
  if not cmd.args then
    return false, "Missing 2 required arguments, args.group and args.klass"
  elseif not cmd.args.group then
    return false, "Missing argument: args.group"
  elseif not cmd.args.klass then
    return false, "Missing argument: args.klass"
  elseif not cmd.args.view then
    return false, "Missing argument: args.view"
  end

  local group = grind.groups[cmd.args.group]
  if not group then return false, "No such application group '" .. cmd.args.group .. "'" end

  local klass = group.klasses[cmd.args.klass]
  if not klass then return false, "No such klass '" .. cmd.args.klass .. "'" end

  local view = klass.views[cmd.args.view]
  if not view then return false, "No such view '" .. cmd.args.view .. "'" end

  return view.skeleton
end)

grind.command("subscribe", function(cmd, watcher)
  -- validate arguments
  if not cmd.args then
    return false, "Missing 2 required arguments, args.group and args.klass"
  elseif not cmd.args.group then
    return false, "Missing argument: args.group"
  elseif not cmd.args.klass then
    return false, "Missing argument: args.klass"
  elseif not cmd.args.view then
    return false, "Missing argument: args.view"
  end

  if cmd.args.group == "*" then
    grind.subscriptions[watcher:whois()] = { "*", "*", "*", watcher, filters = {} }
    table.insert(grind.keepers, watcher)
    log:info("Watcher#" .. watcher:whois() .. " has subscribed to *")
    return "Subscribed."
  end

  local group = grind.groups[cmd.args.group]
  if not group then return false, "No such application group '" .. cmd.args.group .. "'" end

  local klass = group.klasses[cmd.args.klass]
  if not klass then return false, "No such klass '" .. cmd.args.klass .. "'" end

  local view = klass.views[cmd.args.view]
  if not view then return false, "No such view '" .. cmd.args.view .. "'" end

  local sub = grind.subscriptions[watcher:whois()]
  if sub and sub[1] == group.label and sub[2] == klass.label and sub[3] == view.label then
    return false, "Already subscribed."
  end

  grind.subscriptions[watcher:whois()] = { group.label, klass.label, view.label, watcher, filters = {} }
  
  -- mark the view as active inside the format its klass belongs to
  for format in ilist(klass.formats) do
    if not group.formats[format].active_klasses[klass.label] then
      group.formats[format].active_klasses[klass.label] = {}
      group.formats[format].nr_active_klasses =
        group.formats[format].nr_active_klasses + 1
    end
    table.insert(group.formats[format].active_klasses[klass.label], view)
  end

  log:info("Watcher#" .. watcher:whois() .. " has subscribed to " .. group.label .. ">>" .. klass.label .. ">>" .. view.label)
  return true
end)

grind.command("add_filters", function(cmd, watcher)
  local sub = grind.subscriptions[watcher:whois()]
  if not sub then
    return false, "You must subscribe to a view first!"
  end

  table.dump(cmd)

  local filters = {}
  for field, pair in pairs(cmd.args) do
    if type(pair) ~= "table" then
      return false, "Invalid command structure; field value must be a table: { is_regex = bool, value = string }"
    end

    if pair.is_regex then
      local regex = create_regex(pair.value)
      if regex then
        filters[field] = { true, regex, pair.is_negated }
      end
    else
      filters[field] = { false, pair.value, pair.is_negated }
    end
    log:info("Filter defined for " .. watcher:whois() .. ": " .. field .. " => " .. pair.value .. "(" .. tostring(pair.is_regex) .. ")")
  end

  sub.filters = filters

  return true
end)

grind.command("clear_filters", function(cmd, watcher)
  local sub = grind.subscriptions[watcher:whois()]
  if not sub then
    return false, "You must subscribe to a view first!"
  end
  sub.filters = {}
end)

grind.command("purge", function(cmd)
  local purge_cmd = json.encode({ command = "purge" })
  for w in ilist(grind.watchers) do
    local sub = grind.subscriptions[w:whois()]
    if sub and sub[1] == '*' then -- it's a keeper
      log:notice("Ordering Keeper#" .. w:whois() .. " to purge its archive.")
      w:send(purge_cmd)
    end
  end
end)

grind.command("reload", function(cmd)
  -- grind.stop();
  -- grind.start();

  -- return true, "Reloaded."
  return false, "Reloading is currently disabled."
end)

grind.command("leftovers", function(cmd, watcher)
  return grind.leftovers()
end)
