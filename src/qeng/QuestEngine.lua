local _, addon = ...
local tokens = addon.QuestScriptTokens
local QuestLog, QuestStatus = addon.QuestLog, addon.QuestStatus

local logger = addon.QuestEngineLogger:NewLogger("Core", addon.LogLevel.info)

-- QuestEngine is the source of truth for all quest evaluation logic
local QuestEngine = {
  definitions = {
    parameters = {},
    conditions = {},
    checkpoints = {},
    objectives = {},
  }
}
addon.QuestEngine = QuestEngine

-- Local vars for easier reference within this file
local parameters = QuestEngine.definitions.parameters
local conditions = QuestEngine.definitions.conditions
local checkpoints = QuestEngine.definitions.checkpoints
local objectives = QuestEngine.definitions.objectives

--------------------
-- Public methods --
--------------------

function QuestEngine:AddDefinition(defType, name, val)
  local defs = QuestEngine.definitions

  if not defs[defType] then
    logger:Fatal("Failed to create definition: '%s' is not a recognized definition type", tostring(defType))
    return
  end

  if type(name) ~= "string" or name == "" then
    logger:Fatal("Failed to create %s: '%s' is not a valid definition name", defType, tostring(name))
    return
  end

  if defs[defType][name] then
    logger:Fatal("Failed to create %s: '%s' is already a registered %s", defType, name, defType)
    return
  end

  defs[defType][name] = val
end

function QuestEngine:Validate(quest)
  assert(type(quest.questId) == "string" and quest.questId ~= "", "questId is required")
  assert(type(quest.name) == "string" and quest.name ~= "", "quest name is required")
  assert(type(quest.objectives) == "table", "quest objectives must be defined")

  for _, obj in ipairs(quest.objectives) do
    assert(type(obj.id) == "string" and obj.id ~= "", "objective id is required")
    assert(type(obj.name) == "string" and obj.name ~= "", "objective name is required")

    local objTemplate = objectives[obj.name]
    assert(objTemplate, addon:Enquote(obj.name).." is not a valid objective")

    assert(type(obj.goal) == "number" and obj.goal > 0, addon:Enquote(obj.name).." objective must have a goal > 0")
    assert(type(obj.progress) == "number" and obj.progress >= 0, addon:Enquote(obj.name).." objective must have progress >= 0")

    assert(type(obj.conditions) == "table", addon:Enquote(obj.name).." must have conditions defined")
    for condName, _ in pairs(obj.conditions) do
      local condition = objTemplate.conditions[condName]
      assert(condition, addon:Enquote(condName).." is not a valid condition for objective "..addon:Enquote(objTemplate.name))
    end
  end
end

function QuestEngine:EvaluateStart(quest)
  if not quest.start then return true end
  return checkpoints[tokens.CMD_START]:Evaluate(quest.start)
end

function QuestEngine:EvaluateComplete(quest)
  if not quest.complete then return true end
  return checkpoints[tokens.CMD_COMPLETE]:Evaluate(quest.complete)
end

function QuestEngine:EvaluateRecommendations(quest)
  if not quest.recommended then return true end
  return checkpoints[tokens.CMD_REC]:Evaluate(quest.recommended)
end

function QuestEngine:EvaluateRequirements(quest)
  if not quest.required then return true end
  return checkpoints[tokens.CMD_REQ]:Evaluate(quest.required)
end

function QuestEngine:StartTracking(quest)
  -- sanity check: validate quest before tracking it
  QuestEngine:Validate(quest)

  local didStartTracking = false
  for _, obj in pairs(quest.objectives) do
    -- All active instances of a created objective are stored together
    -- so that they can be quickly evaluated together
    if not objectives[obj.name].active[obj.id] then
      objectives[obj.name].active[obj.id] = obj
      didStartTracking = true
    end
  end

  if didStartTracking then
    addon.AppEvents:Publish("QuestTrackingStarted", quest)
    logger:Trace("Started tracking quest: %s", quest.name)
  else
    logger:Trace("All objective are already being tracked for: %s", quest.name)
  end

  return didStartTracking
end

function QuestEngine:StopTracking(quest)
  local didStopTracking = false
  for _, obj in pairs(quest.objectives) do
    if objectives[obj.name].active[obj.id] then
      objectives[obj.name].active[obj.id] = nil
      didStopTracking = true
    end
  end

  if didStopTracking then
    addon.AppEvents:Publish("QuestTrackingStopped", quest)
    logger:Trace("Stopped tracking quest: %s", quest.name)
  else
    logger:Trace("No objectives were being tracked for: %s", quest.name)
  end

  return didStopTracking
end

----------------------
-- Lifecycle Events --
----------------------

function QuestEngine:Init()
  -- Ensure everything can be setup, then wire up objectives into the engine
  for _, objective in pairs(objectives) do
    objective:Init()
  end
  logger:Debug("QuestEngine loaded OK!")

  addon.AppEvents:Subscribe("QuestDeleted", function(quest)
    QuestEngine:StopTracking(quest)
  end)

  addon.AppEvents:Subscribe("QuestDataReset", function()
    for _, objective in pairs(objectives) do
      objective.active = {}
    end
    logger:Trace("QuestDataReset - Stopped tracking all objectives")
  end)
end

function QuestEngine:StartTrackingQuestLog()
  local quests = QuestLog:FindByQuery(function(q) return q.status == QuestStatus.Active end)
  for _, q in pairs(quests) do
    local ok, err = pcall(QuestEngine.StartTracking, QuestEngine, q)
    if not ok then
      logger:Error("Failed to start quest tracking for quest \"%s\": %s", q.name, err)
    end
  end
end