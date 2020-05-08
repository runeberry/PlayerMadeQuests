local _, addon = ...
addon:traceFile("QuestEngine.lua")

addon.QuestEngine = {}

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

local function evaluateObjective(rule, obj, ...)
  local ok, result
  if rule.BeforeCheckConditions then
    ok, result = addon:catch(rule.BeforeCheckConditions, rule, obj, ...)
    if not(ok) then
      addon:error("Error during BeforeCheckConditions for '", obj.id, "':", result)
      return
    elseif result == false then
      return
    end
  end

  for name, val in pairs(obj.conditions) do
    local condition = conditions[name]
    ok, result = addon:catch(condition.CheckCondition, condition, obj, val)
    if not(ok) then
      addon:error("Error evaluating condition '", name,"' for '", obj.id, "':", result)
      return
    elseif result == false then
      -- If any result was false, stop evaluating conditions
      -- But still let the rule have the final say on the result
      break
    end
  end

  if rule.AfterCheckConditions then
    ok, result = addon:catch(rule.AfterCheckConditions, rule, obj, result, ...)
    if not(ok) then
      addon:error("Error during AfterCheckConditions for '", obj.id, "':", result)
      return
    end
  end

  -- Coerce non-numeric results to a goal progress number
  if type(result) ~= "number" then
    if result == false then
      -- False will result in no objective progress
      result = 0
    else
      -- True, nil, or non-numeric values will advance the objective by 1
      result = 1
    end
  end

  return result
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