local _, addon = ...

local logger = addon.Logger:NewLogger("Compiler", addon.LogLevel.info)

addon.QuestScriptCompiler = {}

local commands = {}
local objectives = {}
local scripts = {}
local cleanNamePattern = "^[%l%d]+$"

--[[
  Registers an arbitrary script by the specified unique name.
  Reference this script name in QuestScript.lua and it will be attached
  to the associated item and executed at the appropriate point in the quest lifecycle.
--]]
function addon.QuestScriptCompiler:AddScript(itemName, methodName, fn)
  if not itemName or itemName == "" then
    logger:Error("AddScript: itemName is required")
    logger:Debug("methodName:", methodName)
    return
  end
  if not methodName or methodName == "" then
    logger:Error("AddScript: methodName is required")
    logger:Debug("itemName:", itemName)
    return
  end

  local existing = scripts[itemName]
  if not existing then
    existing = {}
    scripts[itemName] = existing
  end

  if existing[methodName] then
    addon.Logger:Error("AddScript: script is already registered for", itemName, "with name", methodName)
    return
  end

  existing[methodName] = fn
end

--[[
  Returns the string value of the requested arg
  If multiple keys are specified, the first one found will be returned
  If multiple values were set, returns the last value specified
  If no value was set, returns nil
--]]
function addon.QuestScriptCompiler:GetArgsValue(args, ...)
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
function addon.QuestScriptCompiler:GetArgsTable(args, ...)
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
function addon.QuestScriptCompiler:GetArgsSet(args, ...)
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

local Q_start_ptn, Q_end_ptn = [=[^(['"])]=], [=[(['"])$]=]
local SQ_start_ptn, DQ_start_ptn, SQ_end_ptn, DQ_end_ptn = [[^(')]], [[^(")]], [[(')$]], [[(")$]]
local escSQ_end_ptn, escDQ_end_ptn = [[(\)(')]], [[(\)(")]]
local esc_ptn = [=[(\*)['"]$]=]

local function parseArgs(line)
  --Normalize spacing around named arguments
  line = line:gsub([=[([^\])%s*=%s*(%S)]=], "%1= %2")

  -- Split parts on space, but keep quoted groups together
  -- Solution adapted from: https://stackoverflow.com/a/28664691
  local args = {
    ordered = {},
    named = {}
  }

  local buf, quoted, pname
  for str in line:gmatch("%S+") do
    local SQ_start = str:match(SQ_start_ptn)
    local SQ_end = str:match(SQ_end_ptn)
    local DQ_start = str:match(DQ_start_ptn)
    local DQ_end = str:match(DQ_end_ptn)
    local escSQ_end = str:match(escSQ_end_ptn)
    local escDQ_end = str:match(escDQ_end_ptn)
    local escaped = str:match(esc_ptn)
    if not quoted and SQ_start and (not SQ_end or escSQ_end) then
      buf, quoted = str, SQ_start
    elseif not quoted and DQ_start and (not DQ_end or escDQ_end) then
      buf, quoted = str, DQ_start
    elseif buf and (SQ_end == quoted or DQ_end == quoted) and #escaped % 2 == 0 then
      str, buf, quoted = buf .. ' ' .. str, nil, nil
    elseif buf then
      buf = buf .. ' ' .. str
    end
    if not buf then
      -- Remove quotes and escaped characters ["'=]
      str = str:gsub(Q_start_ptn,""):gsub(Q_end_ptn,""):gsub([=[(\)(["'=])]=], "%2")
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
  local commandName = addon.QuestScriptCompiler:GetArgsValue(args, 1)
  if not commandName then
    error("No command name was specified")
  end

  local command = commands[commandName]
  if not command then
    error("No command exists with name: "..commandName)
  end

  if not command.scripts or not command.scripts.Parse then
    error("No Parse script is defined for command: "..commandName)
  end

  command.scripts.Parse(quest, args)
end

local function initQuestScript(qsconfig)
  local function validateAndRegister(set, name, item)
    if not name or name == "" then
      error("Name/alias cannot be nil or empty")
    end
    if type(name) ~= "string" or not name:match(cleanNamePattern) then
      error("Name/alias must only contain lowercase alphanumeric characters")
    end
    if set[name] and set[name] ~= item then
      error("An item is already registered with name/alias: "..name)
    end
    set[name] = item
  end

  local function setup(set, item)
    local name = item.name
    -- An item's primary alias is its name
    validateAndRegister(set, name, item)

    local alias = item.alias
    if alias then
      if type(alias) == "string" then
        -- Single alias
        validateAndRegister(set, alias, item)
      elseif type(alias) == "table" then
        -- Multiple aliases
        for _, al in ipairs(alias) do
          validateAndRegister(set, al, item)
        end
      else
        error("Unrecognized alias type ("..type(alias)..") for:"..name)
      end
    end

    local itemScripts = item.scripts
    if itemScripts then
      -- Replace the array of script names with a table like: { name = function }
      local newScripts = {}
      for _, methodName in pairs(itemScripts) do
        local method = scripts[name]
        if not method then
          error("No scripts registered for: "..name)
        end
        method = method[methodName]
        if not method then
          error("No script registered for "..name.." with name: "..methodName)
        end
        if type(method) ~= "function" then
          error("Non-function registered as script for "..name..": "..methodName)
        end
        newScripts[methodName] = method
      end
      item.scripts = newScripts
    end

    local params = item.params
    if params then
      local indexed = {}
      for _, param in ipairs(params) do
        -- Recursively set up parameters exactly like their parent items
        setup(indexed, param)
      end
      item._paramsByName = indexed
    end
  end

  for _, command in ipairs(qsconfig.commands) do
    setup(commands, command)
  end
  for _, objective in ipairs(qsconfig.objectives) do
    setup(objectives, objective)
  end
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
function addon.QuestScriptCompiler:Compile(script, params)
  local parameters
  if params then
    parameters = addon:CopyTable(params)
  else
    parameters = {}
  end
  if script ~= nil and script ~= "" then
    for line in script:gmatch("[^\r\n]+") do
      if not line:match("^%s*$") then
        local args = parseArgs(line)
        runCommand(parameters, args)
      end
    end
  end
  logger:Trace("Quest compiled")
  -- logger:Table(quest)
  return parameters
end

addon:onload(function()
  initQuestScript(addon.QuestScript)
  logger:Debug("QuestScript loaded OK!")
  addon.AppEvents:Publish("CompilerLoaded", objectives)
end)