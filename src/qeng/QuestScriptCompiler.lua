local _, addon = ...
local ParseYaml = addon.ParseYaml
local logger = addon.Logger:NewLogger("Compiler", addon.LogLevel.info)
local GetUnitName = addon.G.GetUnitName

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

local function parseConditionValueText(obj, condName)
  local condVal = obj.conditions and obj.conditions[condName]
    if condVal == nil then return end

  if type(condVal) ~= "table" then
    return condVal
  end

  local len = addon:tlen(condVal)
  if len == 0 then return end
  if len == 1 then
    for v in pairs(condVal) do
      return v
    end
  elseif len > 1 then
    local ret = ""
    local i = 1
    for v in pairs(condVal) do
      if i == len then
        return ret.." or "..v
      else
        ret = ret..", "..v
      end
      i = i + 1
    end
  end
end

local parseDisplayText

local rules
rules = {
  standard = {
    { -- Contents of bracketed sets are analyzed recursively, innermost first
      pattern = "%b[]",
      fn = function(str, obj)
        -- print("     match: []", str)
        str = str:match("^%[(.+)%]$") -- extract contents from brackets

        local condition, valIfTrue, valIfFalse
        for _, br in ipairs(rules.bracketed) do
          -- Pattern returns up to three capture groups
          condition, valIfTrue, valIfFalse = str:match(br.pattern)
          if condition then
            -- If matched, an associated function will map to the appropriate values
            condition, valIfTrue, valIfFalse = br.fn(condition, valIfTrue, valIfFalse)
            -- print("     ^ ctf:", condition, valIfTrue, valIfFalse)
            break
          end
        end

        if not condition then
          -- Unable to parse bracket formula, try to parse the string as a whole
          -- print("     ^ unmatched bracket formula")
          return parseDisplayText(str, obj)
        end

        -- Determine which text to parse next, based on condition's parsed value
        local ret
        condition = parseDisplayText(condition, obj)
        if condition and condition ~= "" then
          ret = valIfTrue
        else
          ret = valIfFalse
        end
        ret = ret or "" -- As a failsafe, never send nil to parse

        return parseDisplayText(ret, obj)
      end
    },
    { -- Any %var gets the value for the mapped condition returned
      pattern = "%%%w+",
      fn = function(str, obj)
        -- print("     match: %var", str)
        local template = objectives[obj.name]
        if not template then return str end

        str = str:sub(2) -- Remove the leading %
        -- Look for global handlers for this var first, like %p and %g
        local handler = addon.QuestScript.globalDisplayTextVars[str]
        if not handler then
          -- Otherwise, look for objective-specific handlers
          local dt = objectives[obj.name].displaytext
          if dt and dt.vars then
            handler = dt.vars[str]
          end
        end
        if type(handler) == "string" then
          -- Token values represent the name of the condition value to return
          -- print("     ^ handler:", handler)
          return parseConditionValueText(obj, handler) or ""
        elseif type(handler) == "function" then
          -- Var handlers can be configured inline within QuestScript
          -- print("     ^ handler: function")
          return tostring(handler(obj) or "")
        else
          -- No valid handler found, return it raw
          -- print("     ^ handler: none")
          return "%"..str
        end
      end
    }
  },
  bracketed = {
    { -- If A, then show B, else show C
      pattern = "^(.-):(.-)|(.-)$",
      fn = function(a, b, c)
        -- print("     ^ match: [a:b|c]")
        return a, b, c
      end
    },
    { -- If A, then show A, else show B
      pattern = "^(.-)|(.-)$",
      fn = function(a, b)
        -- print("     ^ match: [a|b]")
        return a, a, b
      end
    },
    { -- If A, then show B, else show nothing
      pattern = "^(.-):(.-)$",
      fn = function(a, b)
        -- print("     ^ match: [a:b]")
        return a, b, nil
      end
    },
    { -- If A, then show A, else show nothing
      -- A courtesy space is added after the var to make this more useful
      pattern = "^(.-)$",
      fn = function(a)
        -- print("     ^ match: [a]")
        return a, a.." ", nil
      end
    }
  }
}

parseDisplayText = function(text, obj)
  -- print("=> received:", text)
  for _, mod in ipairs(rules.standard) do
    text = addon:strmod(text, mod.pattern, mod.fn, obj)
  end
  -- Once all substitutions are made, clean up extra spaces
  -- print("<= resolved:", text)
  return text
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
    if param.alias then
      validateAndRegister(set, param.alias, param)
    end

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

-- Valid values for scope are: log [default], progress, quest, full
function addon.QuestScriptCompiler:GetDisplayText(obj, scope)
  scope = scope or "log"
  local displayText
  if obj.displaytext then
    -- Custom displayText is set for this instance of the objective
    displayText = obj.displaytext[scope]
  end
  if not displayText then
    -- Otherwise, use default displayText for this objective
    local objTemplate = objectives[obj.name]
    assert(objTemplate, "Invalid objective: "..obj.name)
    assert(objTemplate.displaytext, "No default displaytext is defined for objective: "..obj.name)
    -- todo: specify one of: log, progress, quest, full
    displayText = objTemplate.displaytext[scope]
  end

  assert(displayText, "Cannot determine how to display text for objective: "..obj.name.." in scope.."..scope)
  return parseDisplayText(displayText, obj)
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
    id = addon:CreateID("objective-"..objName.."-%i"),
    name = objName,
    progress = 0, -- All objectives start at 0 progress
    conditions = {}, -- The conditions under which this objective must be completed
  }

  objective.goal = getTypeValidatedParameterValueOrDefault(args.goal, objInfo._paramsByName["goal"], true)
  args.goal = nil

  objective.displaytext = getTypeValidatedParameterValueOrDefault(args.text, objInfo._paramsByName["text"], true)
  if type(objective.displaytext) == "string" then
    -- If a single text value is defined, it's used for all display texts
    objective.displaytext = {
      log = objective.displaytext,
      progress = objective.displaytext,
      quest = objective.displaytext,
    }
  elseif type(objective.displaytext) == "table" then
    -- Only whitelisted text values can be set at the objective level
    -- todo: nested configuration tables should probably be configured in QuestScript
    objective.displaytext = {
      log = objective.displaytext.log,
      progress = objective.displaytext.progress,
      quest = objective.displaytext.quest
    }
  end
  args.text = nil

  for _, param in ipairs(objInfo.params) do
    if param.multiple then
      -- If multiple arg values are allowed, then they will be passed to the
      -- condition handler as a set, such as { value1 = true, value2 = true }
      -- Note: values assigned to an alias in script will be assigned to the primary
      --       condition name in the compiled quest
      local val = args[param.name] or args[param.alias]
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
    -- addon.Logger:Table(yaml)
    yamlToQuest(quest, yaml)
  end

  addon.QuestEngine:Validate(quest)

  logger:Trace("Quest compiled:", quest.questId)
  -- addon.Logger:Table(quest)
  return quest
end

function addon.QuestScriptCompiler:TryCompile(script, params)
  return pcall(addon.QuestScriptCompiler.Compile, addon.QuestScriptCompiler, script, params)
end

addon:onload(function()
  initQuestScript(addon.QuestScript)
  logger:Debug("QuestScript loaded OK!")
  addon.AppEvents:Publish("CompilerLoaded", objectives)
end)