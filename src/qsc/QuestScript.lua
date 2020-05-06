local _, addon = ...
addon:traceFile("QuestScript.lua")

addon.QuestScript = {}

local commands = {}
local cleanNamePattern = "^[%l%d]+$"

--[[
  Returns the string value of the requested arg
  If multiple keys are specified, the first one found will be returned
  If multiple values were set, returns the last value specified
  If no value was set, returns nil
--]]
function addon.QuestScript:GetArgsValue(args, ...)
  for _, key in pairs({...}) do
    if type(key) == "number" then
      return args.ordered[key]
    else
      local value = args.named[key]
      if type(value) == "table" then
        value = value[addon:tlen(value)]
      end
      if value ~= nil then
        return value
      end
    end
  end
end

--[[
  Returns all string values specified for this arg in the order that they were set
  If multiple keys are specified, the first one found will be returned
  If a single value was set, it's returned as a table with one element
  If no value was set, returns nil
--]]
function addon.QuestScript:GetArgsTable(args, ...)
  for _, key in pairs({...}) do
    if type(key) == "number" then
      return { args.ordered[key] }
    else
      local value = args.named[key]
      if type(value) == "string" then
        value = { value }
      end
      if value ~= nil then
        return value
      end
    end
  end
end

--[[
  Returns all distinct string values specified for this arg as a value-indexed set
  If multiple keys are specified, then the distinct values for ALL args will be returned
  If a single value was set, it's returned as a table with one element
  If no value was set, returns nil
--]]
function addon.QuestScript:GetArgsSet(args, ...)
  local set = {}
  for _, key in pairs({...}) do
    local value = self:GetArgsTable(args, key)
    if value ~= nil then
      for _, v in ipairs(value) do
        set[v] = true
      end
    end
  end
  if addon:tlen(set) == 0 then
    return nil
  end
  return set
end

local function parseArgs(line)
  --Normalize spacing around named arguments
  line = line:gsub([=[([^\])%s*=%s*(%S)]=], "%1= %2")

  -- Split parts on space, but keep quoted groups together
  -- Solution adapted from: https://stackoverflow.com/a/28664691
  local args = {
    ordered = {},
    named = {}
  }
  local spat, epat, buf, quoted, pname = [=[^(['"])]=], [=[(['"])$]=]
  for str in line:gmatch("%S+") do
    local squoted = str:match(spat)
    local equoted = str:match(epat)
    local escaped = str:match([=[(\*)['"]$]=])
    if squoted and not quoted and not equoted then
      buf, quoted = str, squoted
    elseif buf and equoted == quoted and #escaped % 2 == 0 then
      str, buf, quoted = buf .. ' ' .. str, nil, nil
    elseif buf then
      buf = buf .. ' ' .. str
    end
    if not buf then
      -- Remove quotes and escaped characters ["'=]
      str = str:gsub(spat,""):gsub(epat,""):gsub([=[(\)(["'=])]=], "%2")
      if pname then
        -- If the last arg was a param name, then this is its value
        local existing = args.named[pname]
        if existing then
          if type(existing) == "table" then
            -- 3rd or later value, add to table
            table.insert(existing, str)
          else
            -- 2nd value, convert string to table
            args.named[pname] = { existing, str }
          end
        else
          -- 1st value, set as string
          args.named[pname] = str
        end
        pname = nil
      else
        local pn = str:match("^(%w-)=$")
        if pn then
          -- This is the param name, next str will be the value
          pname = pn
        else
          -- This an ordered (unnamed) value
          table.insert(args.ordered, str)
        end
      end
    end
  end
  if buf then error("Missing matching quote for: "..buf) end

  return args
end

local function runCommand(quest, args)
  local commandName = args:GetValue(1)
  if commandName == nil then
    error("No command name was specified")
  end

  local command = commands[commandName]
  if command == nil then
    error("No command exists with name: "..commandName)
  end

  if command.Parse == nil then
    error("No Parse method is defined for command: "..commandName)
  end

  command:Parse(quest, args)
end

function addon.QuestScript:NewCommand(name, ...)
  if name == nil or name == "" then
    addon:error("Failed to build QuestScript command: at least one name is required")
    return {}
  end

  if type(name) ~= "string" or not(name:match(cleanNamePattern)) then
    addon:error("Failed to build QuestScript command: name '"..name.."'must contain only lowercase alphanumeric characters")
    return {}
  end

  if commands[name] ~= nil then
    addon:error("Failed to build QuestScript command: '"..name.."' is already defined")
    return {}
  end

  local command = {
    name = name, -- All aliases for this command will reference the same "name"
  }
  commands[name] = command

  -- A condition can be registered with multiple aliases, index them here
  local aliases = { ... }
  for _, alias in pairs(aliases) do
    if commands[alias] ~= nil then
      addon:error("Failed to build QuestScript alias: '"..alias.."' is already defined")
    else
      commands[alias] = command
    end
  end

  return command
end

--[[
  Parses a QuestScript "file" (set of lines) into an unvalidated quest object.
  The returned object takes on the following format:
  {
    name = "string",
    description = "string",
    objectives = {
      {
        name = "string",
        displayText = "string",
        goal = 1,
        conditions = {
          emote = { "val1": true },
          target = { "val2": true, "val3": true }
        }
      }
    }
  }
--]]
function addon.QuestScript:Compile(script)
  local quest = {}
  if script ~= nil and script ~= "" then
    for line in script:gmatch("[^\r\n]+") do
      if not line:match("^%s*$") then
        local ok, args = addon:catch(parseArgs, line)
        if ok then
          addon:catch(runCommand, quest, args)
        end
      end
    end
  end
  addon:debug("Quest compiled")
  -- addon:logtable(quest)
  return quest
end