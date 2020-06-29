local _, addon = ...
local ParseYaml = addon.ParseYaml
local logger = addon.Logger:NewLogger("Compiler", addon.LogLevel.info)
local unpack = addon.G.unpack

addon.QuestScriptCompiler = {}

local commands = {}
local objectives = {}
local scripts = {}
local cleanNamePattern = "^[%l%d]+$"

local function tryConvert(val, toType)
  local ok, converted = pcall(addon.ConvertValue, addon, val, toType)
  if ok then return converted end
end

-- Each parse mode returns: "objective name", { objective parameters }
local parseMode
parseMode = {
  -- mode: (Shorthand String)
  -- yaml: - kill 5 Chicken
  --  lua: "kill 5 Chicken"
  [1] = function(obj)
    local words = addon:SplitWords(obj)
    local objName, args = words[1], {}

    -- All types will be strings when converting from shorthand
    -- Try to convert them in the same way the yaml parser would
    for i, word in ipairs(words) do
      if i > 1 then
        local converted = tryConvert(word, "number")
        if not converted then
          converted = tryConvert(word, "boolean")
          if not converted then
            converted = word
          end
        end
        args[i-1] = converted
      end
    end

    return objName, args
  end,
  -- mode: (Shorthand string, with optional colon)
  -- yaml: - kill: 5 Chicken
  --  lua: { kill = "5 Chicken" }
  [2] = function(obj)
    local str
    for k, v in pairs(obj) do
      str = k.." "..v
      break
    end
    return parseMode[1](str)
  end,
  -- mode: (Kinda malformed table, but I'll allow it)
  -- yaml: - kill:
  --         goal: 5
  --         target: Chicken
  --  lua: { kill = "yaml.null", goal = 5, target = "Chicken" }
  [3] = function(obj)
    for k, v in pairs(obj) do
      if tostring(v) == "yaml.null" then
        local objName = k
        obj[k] = nil
        return objName, obj
      end
    end
  end,
  -- mode: (Properly formed table, flow style also works)
  -- yaml: - kill:
  --           goal: 5
  --           target: Chicken
  --  lua: { kill = { goal = 5, target = "Chicken" } }
  [4] = function(obj)
    for k, v in pairs(obj) do
      return k, v
    end
  end,
}

local function getCommand(commandName)
  if not commandName then
    error("No command name specified")
  end
  local command = commands[commandName]
  if not command then
    error("No command exists with name: "..commandName)
  end
  if not command.scripts or not command.scripts.Parse then
    error("No Parse script is defined for command: "..commandName)
  end
  return command
end

local function yamlToQuest(quest, yaml)
  for cmd, args in pairs(yaml) do
    local command = getCommand(cmd)
    command.scripts.Parse(quest, args)
  end
end

local function determineParseMode(obj)
  if type(obj) == "string" then
    return 1
  elseif type(obj) == "table" then
    local len, v1 = 0
    for k, v in pairs(obj) do
      len = len + 1
      if len == 1 then
        v1 = v
      end
    end
    if len == 1 then
      if type(v1) == "string" then
        return 2
      elseif type(v1) == "table" then
        return 4
      end
    else
      return 3
    end
  end
end

local function getTypeValidatedParameterValue(val, paramInfo, convert)
  local expectedType = paramInfo.type or "string"
  local actualType = type(val)

  if expectedType == actualType then
    -- Single type is allowed, and they already match
    -- print("    single-type match", paramInfo.name, val, expectedType)
    return val
  elseif type(expectedType) == "table" then
    -- Multiple types are allowed, check for any matches
    for _, t in ipairs(expectedType) do
      if t == actualType then
        -- print("    multi-type match", paramInfo.name, val, t)
        return val
      end
    end
  elseif actualType == "table" and paramInfo.multiple then
    -- Multiple values are supplied, each value must match an expected type
    local val2 = {}
    for k, v in pairs(val) do
      local v2 = getTypeValidatedParameterValue(v, paramInfo, convert)
      if not v2 then
        -- print("    multi-value failure", paramInfo.name, v, actualType, expectedType)
        return
      end
      val2[k] = v2
    end
    return val2
  elseif convert then
    -- All else fails, try to convert the value to an expected type
    if type(expectedType) == "table" then
      for _, t in ipairs(expectedType) do
        -- Multiple types are allowed, try converting to all of them
        local ok, converted = pcall(addon.ConvertValue, addon, val, t)
        if ok then
          -- print("    multi-type conversion", paramInfo.name, converted, t)
          return converted
        end
      end
    else
      -- Single type is allowed, try to convert to that type
      local ok, converted = pcall(addon.ConvertValue, addon, val, expectedType)
      if ok then
        -- print("    single-type conversion", paramInfo.name, converted, expectedType)
        return converted
      end
    end
  end
  -- print("    type validation failure", paramInfo.name, val, actualType, expectedType)
end

local function getTypeValidatedParameterValueOrDefault(val, paramInfo, convert)
  if val == nil and not paramInfo.required then
    -- Non-required parameters can have a default value
    -- If no default value is specified, then nil will be returned
    return paramInfo.default
  end

  return getTypeValidatedParameterValue(val, paramInfo, convert)
end

local function assignShorthandArgs(args, objInfo)
  local shorthand = objInfo.shorthand
  if not shorthand then
    error("Objective "..objInfo.name.." does not have a shorthand form")
  end
  if #args > #shorthand then
    error("Objective "..objInfo.name.." recognizes up to "..#shorthand.." ordered parameters, but got "..#args)
  end

  local skipped = 0
  -- print("----------------")
  for i, paramName in pairs(shorthand) do
    local paramInfo = objInfo._paramsByName[paramName]
    if not paramInfo then
      -- If this happens, then a bad token was assigned in QuestScript configuration
      error("Unrecognized shorthand parameter: "..paramName)
    end
    local argValue = args[i - skipped]
    if getTypeValidatedParameterValue(argValue, paramInfo) then
      -- print("assignment", paramName, argValue)
      args[paramName] = argValue
      args[i - skipped] = nil
    else
      -- Loop to the next shorthand param, but try with this arg value again
      -- print("skipping", paramName, argValue)
      skipped = skipped + 1
    end
  end
end

local function initQuestScript(qsconfig)
  local function validateAndRegister(set, name, param)
    if not name or name == "" then
      error("Name cannot be nil or empty")
    end
    if type(name) ~= "string" or not name:match(cleanNamePattern) then
      error("Name must only contain lowercase alphanumeric characters")
    end
    if set[name] and set[name] ~= param then
      error("An item is already registered with name: "..name)
    end
    set[name] = param
  end

  local function setup(set, param)
    local name = param.name
    validateAndRegister(set, name, param)

    local itemScripts = param.scripts
    if itemScripts then
      -- Replace the array of script names with a table like: { name = function }
      local newScripts = {}
      for _, methodName in pairs(itemScripts) do
        local method = scripts[name]
        if not method then
          error("No scripts registered for: "..name)
        end
        if type(methodName) ~= "string" then
          error("Non-string registered as methodName for "..name)
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
      param.scripts = newScripts
    end

    local params = param.params
    if params then
      local nameIndexed, positionIndexed = {}, {}

      for _, p in ipairs(params) do
        -- Recursively set up parameters exactly like their parent items
        setup(nameIndexed, p)
        if p.position then
          if positionIndexed[p.position] then
            error("Multiple parameters specified for position "..p.position.." on "..name)
          end
          positionIndexed[p.position] = p
        end
      end
      param._paramsByPosition = positionIndexed
      param._paramsByName = nameIndexed
    end
  end

  for _, command in ipairs(qsconfig.commands) do
    setup(commands, command)
  end
  for _, objective in ipairs(qsconfig.objectives) do
    setup(objectives, objective)
  end
end

--------------------
-- Public Methods --
--------------------

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

function addon.QuestScriptCompiler:GetCommandInfo(cmdToken, paramToken)
  local command = commands[cmdToken]
  if not paramToken then return command end
  return command._paramsByName[paramToken]
end

function addon.QuestScriptCompiler:GetObjectiveInfo(objToken, paramToken)
  local obj = objectives[objToken]
  if not paramToken then return obj end
  return obj._paramsByName[paramToken]
end

function addon.QuestScriptCompiler:ParseObjective(obj)
  local mode = determineParseMode(obj)
  if not mode then
    error("Cannot determine how to parse objective (type: "..type(obj)..")")
  end

  local objName, args = parseMode[mode](obj)
  if not objName then
    error("Cannot determine name of objective")
  end

  objName = objName:lower()
  local objInfo = objectives[objName]
  if not objInfo then
    error("Unknown objective name: "..objName)
  end

  if args[1] then
    assignShorthandArgs(args, objInfo)
  end

  local objective = {
    --id = addon:CreateID("objective:"..objName.."-%i"),
    --_parent = objectives[p1], -- The objective contains a reference to its parent definition
    name = objName,
    --displayText = nil,
    --progress = 0, -- All objectives start at 0 progress
    conditions = {}, -- The conditions under which this objective must be completed
    --metadata = {}, -- Additional data for this objective that can be written to save
    --tempdata = {} -- Additional data that will not be written to save
  }

  objective.goal = getTypeValidatedParameterValueOrDefault(args.goal, objInfo._paramsByName["goal"], true)
  args.goal = nil

  objective.displayText = getTypeValidatedParameterValueOrDefault(args.text, objInfo._paramsByName["text"], true)
  args.text = nil

  args._parentName = objName
  args._parent = objInfo

  for _, param in ipairs(objInfo.params) do
    if param.multiple then
      -- If multiple arg values are allowed, then they will be passed to the
      -- condition handler as a set, such as { value1 = true, value2 = true }
      local val = args[param.name]
      if val then
        if type(param.name) ~= "table" then
          val = { val }
        end
        objective.conditions[param.name] = addon:DistinctSet(val)
      end
    else
      -- Otherwise, simply pass a single value to the condition handler
      objective.conditions[param.name] = args[param.name]
    end
  end

  return objective
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
  local quest
  if params then
    quest = addon:CopyTable(params)
  else
    quest = {}
  end
  if script ~= nil and script ~= "" then
    local yaml = ParseYaml(script)
    -- addon.Logger:Table(yaml)
    yamlToQuest(quest, yaml)
  end
  logger:Trace("Quest compiled")
  -- addon.Logger:Table(quest)
  return quest
end

addon:onload(function()
  initQuestScript(addon.QuestScript)
  logger:Debug("QuestScript loaded OK!")
  addon.AppEvents:Publish("CompilerLoaded", objectives)
end)