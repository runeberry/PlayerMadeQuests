local _, addon = ...
addon:traceFile("QuestEngine.lua")

addon.QuestEngine = {}

local commands = {}
local rules = {}
local conditions = {}
local quests = {}
local cleanNamePattern = "^[%l%d]+$"
local loaded = false

addon.QuestStatus = {
  Active = "Active",
  Failed = "Failed",
  Completed = "Completed",
}
local status = addon.QuestStatus

addon:OnSaveDataLoaded(function()
  addon.QuestEngine:Load()
  loaded = true
end)

------------------------
-- Predefined Methods --
------------------------

local function objective_HasCondition(obj, name)
  return obj.conditions and obj.conditions[name] and true
end

local function objective_SetMetadata(obj, name, value, persistent)
  if persistent then
    -- These values will be written to SavedVariables
    obj.metadata[name] = value
  else
    -- These values will not be saved. Use for non-serializable data.
    obj._tempdata[name] = value
  end
end

local function objective_GetMetadata(obj, name)
  if obj._tempdata[name] ~= nil then
    return obj._tempdata[name]
  elseif obj.metadata[name] ~= nil then
    return obj.metadata[name]
  end
  return nil
end

local function objective_GetDisplayText(obj)
  if obj._rule.GetDisplayText then
    return obj._rule:GetDisplayText(obj)
  else
    return obj.name
  end
end

local function quest_StartTracking(quest)
  -- All objectives created for a rule are stored together
  -- so that they can be quickly evaluated together
  for _, obj in pairs(quest.objectives) do
    obj._rule.objectives[obj.id] = obj
  end
  addon.AppEvents:Publish("QuestTrackingStarted", quest)
end

local function quest_StopTracking(quest)
  for _, obj in pairs(quest.objectives) do
    obj._rule.objectives[obj.id] = nil
  end
  addon.AppEvents:Publish("QuestTrackingStopped", quest)
end

---------------------------------------------------
-- Private functions: Quest objective evaluation --
---------------------------------------------------

local function evaluateObjective(rule, obj, ...)
  local ok, beforeResult, checkResult, afterResult
  if rule.BeforeCheckConditions then
    ok, beforeResult = addon:catch(rule.BeforeCheckConditions, rule, obj, ...)
    if not(ok) then
      addon:error("Error during BeforeCheckConditions for '", obj.id, "':", beforeResult)
      return
    elseif beforeResult == false then
      return
    end
  end

  -- CheckCondition is expected to return a boolean value only:
  -- true if the condition was met, false otherwise
  for name, val in pairs(obj.conditions) do
    local condition = conditions[name]
    ok, checkResult = addon:catch(condition.CheckCondition, condition, obj, val)
    if not(ok) then
      addon:error("Error evaluating condition '", name,"' for '", obj.id, "':", checkResult)
      return
    elseif checkResult ~= true  then
      -- If any result was not true, stop evaluating conditions
      --addon:trace("Condition '"..name.."' evaluated: "..checkResult.."")
      break
    end
  end

  -- AfterCheckConditions may take the result from CheckCondition and make a final ruling by
  -- returning either a boolean or a number to represent objective progress
  if rule.AfterCheckConditions then
    ok, afterResult = addon:catch(rule.AfterCheckConditions, rule, obj, checkResult, ...)
    if not(ok) then
      addon:error("Error during AfterCheckConditions for '", obj.id, "':", afterResult)
      return
    elseif afterResult ~= nil then
      -- If the After function returns a value, then that value will override the result of CheckCondition
      checkResult = afterResult
    end
  end

  -- Coerce non-numeric results to a goal progress number
  if checkResult == true then
    -- A boolean result of true will advance the objective by 1
    checkResult = 1
  elseif type(checkResult) ~= "number" then
    -- False, nil, or non-numeric values will result in no objective progress
    checkResult = 0
  end

  return checkResult
end

local function wrapRuleHandler(rule)
  -- Given an arbitrary list of game event args, handle them as follows
  return function(...)
    -- addon:debug("Evaluating rule:", rule.name, "(", addon:tlen(rule.objectives), "objectives )")
    -- addon:logtable(rule.objectives)
    -- Completed objectives will be tracked and removed from the list
    local completed = {}
    local anychanged = false

    -- For each objective that is backed by this rule
    for id, obj in pairs(rule.objectives) do
      if obj.progress >= obj.goal then
        -- The objective is already completed, nothing to do
        completed[id] = obj
      else
        local result = evaluateObjective(rule, obj, ...)
        -- addon:debug("    Result:", result)

        if result > 0 then
          anychanged = true
          obj.progress = obj.progress + result
          local quest = obj._quest

          -- Sanity checks: progress must be >= 0, and progress must be an integer
          obj.progress = math.max(math.floor(obj.progress), 0)

          addon.AppEvents:Publish("ObjectiveUpdated", obj)
          addon.AppEvents:Publish("QuestUpdated", quest)

          if obj.progress >= obj.goal then
            -- Mark objective for removal from further checks
            completed[id] = obj
            addon.AppEvents:Publish("ObjectiveCompleted", obj)

            local questCompleted = true
            for _, qobj in pairs(quest.objectives) do
              if qobj.progress < qobj.goal then
                questCompleted = false
                break
              end
            end
            if questCompleted then
              quest.status = status.Completed
              addon.AppEvents:Publish("QuestCompleted", quest)
              quest:StopTracking()
            end
          end
        end
      end
    end

    for id, _ in pairs(completed) do
      -- Stop trying to update that objective on subsequent game events
      rule.objectives[id] = nil
    end

    if anychanged then
      addon.QuestEngine:Save()
    end
  end
end

------------------
-- Constructors --
------------------

function addon.QuestEngine:NewCommand(name, ...)
  if name == nil or name == "" then
    addon:error("Failed to build QuestEngine command: at least one name is required")
    return {}
  end

  if type(name) ~= "string" or not(name:match(cleanNamePattern)) then
    addon:error("Failed to build QuestEngine command: name '"..name.."'must contain only lowercase alphanumeric characters")
    return {}
  end

  if commands[name] ~= nil then
    addon:error("Failed to build QuestEngine command: '"..name.."' is already defined")
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
      addon:error("Failed to build QuestEngine alias: '"..alias.."' is already defined")
    else
      commands[alias] = command
    end
  end

  return command
end

function addon.QuestEngine:NewRule(name)
  if name == nil or name == "" then
    addon:error("Failed to build quest rule: name is required")
    return {}
  end

  if type(name) ~= "string" or not(name:match(cleanNamePattern)) then
    addon:error("Failed to build quest rule: name '"..name.."'must contain only lowercase alphanumeric characters")
    return {}
  end

  if rules[name] ~= nil then
    addon:error("Failed to build quest rule: '"..name.."' is already defined")
    return {}
  end

  local rule = {
    name = name,
    objectives = {}
  }

  addon.RuleEvents:Subscribe(name, wrapRuleHandler(rule))
  rules[name] = rule
  -- addon:trace("Registered quest rule: '" .. rule.name .. "'")
  return rule
end

function addon.QuestEngine:NewCondition(name)
  if name == nil or name == "" then
    addon:error("Failed to build condition: name is required")
    return {}
  end

  if type(name) ~= "string" or not(name:match(cleanNamePattern)) then
    addon:error("Failed to build condition: name '"..name.."'must contain only lowercase alphanumeric characters")
    return {}
  end

  if conditions[name] ~= nil then
    addon:error("Failed to build condition: '"..name.."' is already defined")
    return {}
  end

  local condition = {
    name = name
  }

  conditions[name] = condition
  return condition
end

function addon.QuestEngine:NewQuest(parameters)
  parameters.name = parameters.name or error("Failed to create quest: quest name is required")

  local quest = addon:CopyTable(parameters)
  quest.id = quest.id or addon:CreateID("quest-%i")
  quest.status = quest.status or status.Active
  quest.objectives = quest.objectives or {}

  for _, obj in pairs(quest.objectives) do
    obj.name = obj.name or error("Failed to create quest: objective name is required")
    obj._rule = rules[obj.name] or error("Failed to create quest: '"..obj.name.."' is not a valid rule")
    obj._quest = quest -- Add reference back to this obj's quest
    obj._tempdata = {}

    obj.id = obj.id or addon:CreateID("objective-"..obj.name.."-%i")
    obj.progress = obj.progress or 0
    obj.goal = obj.goal or 1
    obj.conditions = obj.conditions or {}
    obj.metadata = obj.metadata or {}

    -- Add predefined methods here
    obj.HasCondition = objective_HasCondition
    obj.GetMetadata = objective_GetMetadata
    obj.SetMetadata = objective_SetMetadata
    obj.GetDisplayText = objective_GetDisplayText

    for name, _ in pairs(obj.conditions) do
      local condition = conditions[name]
      if condition == nil then
        error("Failed to create quest: '"..name.."' is not a valid condition")
      end
      if condition.CheckCondition == nil then
        error("Failed to create quest: condition '"..name.."' does not have a CheckCondition method")
      end
    end
  end

  -- Add predefined methods here
  quest.StartTracking = quest_StartTracking
  quest.StopTracking = quest_StopTracking

  quests[quest.id] = quest
  if loaded then
    addon.AppEvents:Publish("QuestCreated", quest)
  end
  return quest
end

---------------
-- Quest Log --
---------------

function addon.QuestEngine:GetQuestByID(id)
  return quests[id]
end

function addon.QuestEngine:Save()
  local cleaned = addon:CleanTable(addon:CopyTable(quests))
  local serialized = addon.Ace:Serialize(cleaned)
  local compressed = addon.LibCompress:CompressHuffman(serialized)
  addon.SaveData:Save("QuestLog", compressed)
end

function addon.QuestEngine:Load()
  local compressed = addon.SaveData:LoadString("QuestLog")
  -- For some reason the data becomes an empty table when I first access it?
  if compressed == "" then
    -- Nothing to load
    return
  end

  local serialized, msg = addon.LibCompress:Decompress(compressed)
  if serialized == nil then
    error("Error loading quest log: "..msg)
  end

  local ok, saved = addon.Ace:Deserialize(serialized)
  if not(ok) then
    -- 2nd param is an error message if it failed
    error("Error loading quest log: "..saved)
  end

  for _, q in pairs(saved) do
    local qc = addon.QuestEngine:NewQuest(q)
    if qc.status == status.Active then
      qc:StartTracking()
    end
  end

  loaded = true
  addon.AppEvents:Publish("QuestLogLoaded", quests)
end

function addon.QuestEngine:ResetQuestLog()
  for _, quest in pairs(quests) do
    quest:StopTracking()
  end
  quests = {}
  self:Save()
  addon.AppEvents:Publish("QuestLogLoaded", quests)
end

function addon.QuestEngine:PrintQuestLog()
  -- addon:logtable(qlog)
  addon:info("=== You have", addon:tlen(quests), "quests in your log ===")
  for _, q in pairs(quests) do
    addon:info(q.name, "(", q.status, ") [", q.id, "]")
    for _, o in pairs(q.objectives) do
      addon:info("    ", o.name, o.progress, "/",  o.goal)
    end
  end
end

-----------------------------
-- QuestScript Compilation --
-----------------------------

--[[
  Returns the string value of the requested arg
  If multiple keys are specified, the first one found will be returned
  If multiple values were set, returns the last value specified
  If no value was set, returns nil
--]]
function addon.QuestEngine:GetArgsValue(args, ...)
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
function addon.QuestEngine:GetArgsTable(args, ...)
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
function addon.QuestEngine:GetArgsSet(args, ...)
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
  local commandName = addon.QuestEngine:GetArgsValue(args, 1)
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
function addon.QuestEngine:Compile(script)
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