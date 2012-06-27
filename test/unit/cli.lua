local cli = {}

local expand = function(str, size, fill)
  if not fill then fill = ' ' end

  local out = str

  for i=0,size - #str do
    out = out .. fill
  end

  return out
end

local split = function(str, pat)
  local t = {}
  local fpat = "(.-)" .. pat
  local last_end = 1
  local s, e, cap = str:find(fpat, 1)
  while s do
    if s ~= 1 or cap ~= "" then
  table.insert(t,cap)
    end
    last_end = e+1
    s, e, cap = str:find(fpat, last_end)
  end
  if last_end <= #str then
    cap = str:sub(last_end)
    table.insert(t, cap)
  end
  return t
end

local delimit = function(str, size, pad)
  if not pad then pad = 0 end

  local out = ""
  local words = split(str, ' ')

  local offset = 0
  for word_idx,word in pairs(words) do
    out = out .. word .. ' '
    offset = offset + #word
    if offset > size and word_idx ~= #words then
      out = out .. '\n'
      for i=0,pad do out = out .. ' '; end
      offset = 0
    end
  end

  return out
end

function cli:new(name, required_args, optional_args)
  local o = {}
  setmetatable(o, { __index = self })
  self.__index = self

  o.name = name
  o.req = required_args or {}
  o.opt = optional_args or {}
  o.args = arg

  return o
end

function cli:error(msg)
  print(self.name .. ": error: " .. msg .. '; re-run with --help for usage.')
  return false
end

function cli:set_name(name)
  self.name = name
end
function cli:add_arg(name, desc, key)
  table.insert(self.req, { name, desc, key })
end

function cli:add_opt(name, desc, key, default)
  -- is a placeholder value specified? (ie: in '-o FILE', capture the FILE part)
  local name_val = split(name, ' ')
  local name,val = name, ""
  if #name_val > 1 then
    name, val = name_val[1], name_val[#name_val]
  end

  table.insert(self.opt, { name, desc, key, default, val })
end

function cli:parse_args()

  if #self.args < #self.req then
    self:error("missing arguments")
    self:print_usage()
    return false
  end

  if self.args[1] and self.args[1] == "--help" then
    return self:print_help()
  end

  local locate_entry = function(key)
    for _,entry in ipairs(self.opt) do
      if entry[1] == key then return entry,_ end
    end

    return nil, nil
  end

  local args = {}
  -- set up defaults
  for _,entry in ipairs(self.req) do
    args[ entry[3] ] = entry[4] or ""
  end
  for _,entry in ipairs(self.opt) do
    args[ entry[3] ] = entry[4] or ""
  end

  local req_idx = 1

  for arg_idx, arg in ipairs(arg) do
    repeat
      if skip then
        skip = false
        break
      end

      -- print("Argument[" .. arg_idx .. "] => " .. arg)
      local entry = locate_entry(arg)

      -- if it's an optional argument (starts with '-'), it must be listed
      if arg:find('-') == 1 and not entry then
        return self:error("unknown option " .. arg)
      end

      -- it's a required argument
      if not entry then
        -- or it's one too many arguments
        if not self.req[req_idx] then
          return self:error("too many arguments! Can't map '" .. arg .. "'")
        end

        args[ self.req[req_idx][3] ] = arg
        req_idx = req_idx + 1
      else
        -- it's an optional argument
        -- get the value:
        local arg_val = self.args[arg_idx+1]
        if not arg_val then
          return self:error("missing argument value in '" .. entry[1] .. " " .. entry[5] .. "'")
        end

        args[ entry[3] ] = arg_val
        skip = true
      end

    until true
  end

  if req_idx - 1 < #self.req then
    return self:error("missing required arguments")
  end

  return args
end

function cli:print_usage()
  -- print the USAGE heading
  local msg = "Usage: " .. self.name
  if self.opt and #self.opt > 0 then
    msg = msg .. " [OPTIONS] "
  end
  if self.req and #self.req > 0 then
    for _,entry in ipairs(self.req) do
      local arg_key, arg_desc, arg_name =
            entry[1], entry[2], entry[3]

      msg = msg .. " " .. arg_key .. " "
    end
  end

  print(msg)

  -- display help listing
  -- self:print_help()
end

local colsz = { 20, 40 }

function cli:print_help()
  self:print_usage()

  local keysz = 20
  local msg = ""

  if self.req and #self.req > 0 then
    msg = msg .. "\nRequired arguments: \n"

    for _,entry in ipairs(self.req) do
      local arg_key, arg_desc, arg_name =
            entry[1], entry[2], entry[3]

      msg = msg ..
            "  " .. expand(arg_key, keysz) ..
            arg_desc .. "\n"
    end
  end

  if self.opt and #self.opt > 0 then
    msg = msg .. "\nOptional arguments: \n"

    for _,entry in ipairs(self.opt) do
      local arg_key, arg_desc, arg_name, arg_default, arg_ph =
            entry[1], entry[2], entry[3], entry[4], entry[5]

      if arg_default then
        arg_desc = arg_desc .. " (default: " .. arg_default .. ")"
      end

      if arg_ph then
        arg_key = arg_key .. " " .. arg_ph
      end

      msg = msg .. "  " ..
        expand(arg_key, colsz[1]) ..
        delimit(arg_desc, colsz[2], colsz[1] + 2 --[[ margin ]]) .. '\n'
    end
  end

  print(msg)
end

return cli:new("")
