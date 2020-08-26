local _, addon = ...
local ParseYaml = addon.ParseYaml
local logger = addon.Logger:NewLogger("Compiler", addon.LogLevel.info)
local GetUnitName = addon.G.GetUnitName

addon.QuestScriptCompiler = {}
local compiler, tokens = addon.QuestScriptCompiler, addon.QuestScriptTokens

local parsable

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
  local command = addon.QuestScript[commandName]
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
    logger:Trace("Parsing command: %s", cmd)
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

local function assignShorthandArgs(args, objInfo)
  local shorthand = objInfo.shorthand
  if not shorthand then
    error("Objective "..objInfo.name.." does not have a shorthand form")
  end
  if #args > #shorthand then
    error("Objective "..objInfo.name.." recognizes up to "..#shorthand.." ordered parameters, but got "..#args)
  end

  local skipped = 0
  logger:Trace("----------------")
  for i, paramName in pairs(shorthand) do
    if objInfo.params[paramName] then
      -- todo: remove this block, backwards compat for GOAL until that becomes a Condition or something
      local argValue = args[i - skipped]
      if compiler:GetValidatedParameterValue(paramName, { [paramName] = argValue }, objInfo) then
        logger:Trace("assignment %s %s", paramName, tostring(argValue))
        args[paramName] = argValue
        args[i - skipped] = nil
      else
        -- Loop to the next shorthand param, but try with this arg value again
        logger:Trace("skipping %s %s", paramName, tostring(argValue))
        skipped = skipped + 1
      end
    elseif objInfo.conditions[paramName] then
      local argValue = args[i - skipped]
      if compiler:GetValidatedConditionValue(paramName, { [paramName] = argValue }, objInfo) then
        logger:Trace("assignment %s %s", paramName, tostring(argValue))
        args[paramName] = argValue
        args[i - skipped] = nil
      else
        -- Loop to the next shorthand param, but try with this arg value again
        logger:Trace("skipping %s %s", paramName, tostring(argValue))
        skipped = skipped + 1
      end
    else
      logger:Table(objInfo.conditions)
      error("Unrecognized shorthand parameter or condition: "..paramName)
    end
  end
end

--------------------
-- Public Methods --
--------------------

local function find(query, searchSet, resultSet)
  for k, v in pairs(searchSet) do
    if query(v) then
      if resultSet[k] then
        -- This doesn't cause problems yet, but it might someday. Keep an eye on it.
        logger:Warn("QuestScript search: duplicate value for \"%s\" in result set", k)
      else
        resultSet[k] = v
      end
    elseif v.params then
      find(query, v.params, resultSet)
    end
  end
end

function addon.QuestScriptCompiler:Find(query)
  local resultSet = {}
  find(query, addon.QuestScript, resultSet)
  logger:Trace("QuestScript search: %i results", addon:tlen(resultSet))
  return addon:CopyTable(resultSet)
end

function addon.QuestScriptCompiler:GetValidatedParameterValue(token, args, info, options)
  local val = args[token]
  if not info.params then
    -- Something didn't initialize properly, this will fail
    logger:Table(info)
  end
  local paramInfo = info.params[token]
  if not paramInfo then
    if options and options.optional then
      return nil
    end
    error(token.." is not a recognized parameter for "..info.name)
  end

  local expectedType = paramInfo.type or "string"
  local actualType = type(val)

  if expectedType == actualType then
    -- Single type is allowed, and they already match
    logger:Trace("    single-type match %s %s %s", paramInfo.name, tostring(val), expectedType)
    return val
  elseif type(expectedType) == "table" then
    -- Multiple types are allowed, check for any matches
    for _, t in ipairs(expectedType) do
      if t == actualType then
        logger:Trace("    multi-type match %s %s %s", paramInfo.name, tostring(val), t)
        return val
      end
    end
  elseif actualType == "table" and paramInfo.multiple then
    -- Multiple values are supplied, each value must match an expected type
    local val2 = {}
    for k, _ in pairs(val) do
      local v = compiler:GetValidatedParameterValue(k, val, paramInfo, options)
      if not v then
        logger:Debug("    multi-value failure %s %s %s %s", paramInfo.name, tostring(v), actualType, expectedType)
        return
      end
      val2[k] = v
    end
    return val2
  elseif options and options.convert then
    -- All else fails, try to convert the value to an expected type
    if type(expectedType) == "table" then
      for _, t in ipairs(expectedType) do
        -- Multiple types are allowed, try converting to all of them
        local ok, converted = pcall(addon.ConvertValue, addon, val, t)
        if ok then
          logger:Trace("    multi-type conversion %s %s %s", paramInfo.name, tostring(converted), t)
          return converted
        end
      end
    else
      -- Single type is allowed, try to convert to that type
      local ok, converted = pcall(addon.ConvertValue, addon, val, expectedType)
      if ok then
        logger:Trace("    single-type conversion %s %s %s", paramInfo.name, tostring(converted), expectedType)
        return converted
      end
    end
  end
  logger:Debug("    type validation failure %s %s %s %s", paramInfo.name, tostring(val), actualType, expectedType)
end

function addon.QuestScriptCompiler:GetValidatedConditionValue(token, args, info, options)
  local val = args[token]
  if not info.conditions then
    -- Something didn't initialize properly, this will fail
    logger:Table(info)
  end
  local condInfo = info.conditions[token]
  if not condInfo then
    if options and options.optional then
      return nil
    end
    error(token.." is not a recognized condition for "..info.name)
  end

  local expectedType = condInfo.type
  local actualType = type(val)

  if not expectedType then
    -- Any type is allowed, perform no validation
    return val
  end

  if expectedType == actualType then
    -- Single type is allowed, and they already match
    logger:Trace("    single-type match", condInfo.name, tostring(val), expectedType)
    return val
  elseif type(expectedType) == "table" then
    -- Multiple types are allowed, check for any matches
    for _, t in ipairs(expectedType) do
      if t == actualType then
        logger:Trace("    multi-type match", condInfo.name, tostring(val), t)
        return val
      end
    end
  elseif actualType == "table" and condInfo.multiple then
    -- Multiple values are supplied, each value must match an expected type
    local val2 = {}
    for k, _ in pairs(val) do
      local v = compiler:GetValidatedConditionValue(k, val, condInfo, options)
      if not v then
        logger:Debug("    multi-value failure", condInfo.name, tostring(v), actualType, expectedType)
        return
      end
      val2[k] = v
    end
    return val2
  elseif options and options.convert then
    -- All else fails, try to convert the value to an expected type
    if type(expectedType) == "table" then
      for _, t in ipairs(expectedType) do
        -- Multiple types are allowed, try converting to all of them
        local ok, converted = pcall(addon.ConvertValue, addon, val, t)
        if ok then
          logger:Trace("    multi-type conversion", condInfo.name, tostring(converted), t)
          return converted
        end
      end
    else
      -- Single type is allowed, try to convert to that type
      local ok, converted = pcall(addon.ConvertValue, addon, val, expectedType)
      if ok then
        logger:Trace("    single-type conversion", condInfo.name, tostring(converted), expectedType)
        return converted
      end
    end
  end
  logger:Debug("    type validation failure", condInfo.name, tostring(val), actualType, expectedType)
end

local function parseFromArgs(cond, args)
  local val = args[cond.name] or args[cond.alias]
  if not val then
    if cond.required then
      error(cond.name.." is required")
    end
    return
  end

  if cond.Parse then
    val = cond:Parse(val)
  end

  return val
end

function addon.QuestScriptCompiler:ParseConditions(conds, args)
  local conditions = {}

  -- _ will be the alias here, if the param had one
  for _, cond in pairs(conds) do
    -- Note: values assigned to an alias in script will be assigned to the primary
    --       condition name in the compiled quest
    -- For example, values assigned to the "target" alias for "killtarget" will be
    -- assigned to obj.conditions["killtarget"]
    conditions[cond.name] = parseFromArgs(cond, args)
  end

  return conditions
end

-- Use this method at compile-time
function addon.QuestScriptCompiler:ParseDisplayText(args, info)
  local displaytext = compiler:GetValidatedParameterValue(tokens.PARAM_TEXT, args, info, { convert = true })
  if type(displaytext) == "string" then
    -- If a single text value is defined, it's used for all display texts
    displaytext = {
      log = displaytext,
      progress = displaytext,
      quest = displaytext,
    }
  elseif type(displaytext) == "table" then
    -- Only whitelisted text values can be set at the objective level
    -- todo: (#54) nested configuration tables should probably be configured in QuestScript
    -- https://github.com/dolphinspired/PlayerMadeQuests/issues/54
    displaytext = {
      log = displaytext.log,
      progress = displaytext.progress,
      quest = displaytext.quest
    }
  end
  return displaytext
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
  local objInfo = parsable[objName]
  if not objInfo then
    error("Unknown objective name: "..objName)
  end

  if args[1] then
    assignShorthandArgs(args, objInfo)
  end

  local objective = {
    id = addon:CreateID("objective-"..objName.."-%i"),
    name = objName,
    progress = 0, -- All objectives start at 0 progress
    conditions = nil, -- The conditions under which this objective must be completed
  }

  -- All objectives should support a display text parameter
  objective.displaytext = compiler:ParseDisplayText(args, objInfo)
  args[tokens.PARAM_TEXT] = nil

  -- If an objective supports a goal parameter, extract that and use it
  objective.goal = compiler:GetValidatedParameterValue(tokens.PARAM_GOAL, args, objInfo, { convert = true, optional = true })
  args[tokens.PARAM_GOAL] = nil

  -- If the objective does not support a goal parameter,
  -- or if the objective supports a goal parameter but none was specified,
  -- then default the goal to 1
  if not objective.goal then
    objective.goal = 1
  end

  objective.conditions = compiler:ParseConditions(objInfo.conditions, args)

  return objective
end

--[[
  Parses a QuestScript "file" (set of lines) and/or a set of quest parameters
  into a Quest that can be stored in the QuestLog and tracked.
  See QuestLog.lua for the Quest data model.
--]]
local function newQuest()
  local playerName = GetUnitName("player", true)

  return {
    questId = addon:CreateID("quest-"..playerName.."-%i"),
    objectives = {}
  }
end

function addon.QuestScriptCompiler:Compile(script, params)
  local quest = newQuest()
  if params then
    quest = addon:MergeTable(quest, params)
  end

  if script ~= nil and script ~= "" then
    local yaml = ParseYaml(script)
    -- logger:Table(yaml)
    yamlToQuest(quest, yaml)
  end

  quest.addonVersion = addon.VERSION

  addon.QuestEngine:Validate(quest)

  logger:Trace("Quest compiled: %s", quest.questId)
  -- logger:Table(quest)
  return quest
end

function addon.QuestScriptCompiler:TryCompile(script, params)
  return pcall(compiler.Compile, compiler, script, params)
end

function addon.QuestScriptCompiler:Init()
  local queryParsable = function(cmd) return cmd.contentParsable end
  parsable = compiler:Find(queryParsable)
end