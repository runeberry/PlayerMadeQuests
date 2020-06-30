local _, addon = ...
addon:traceFile("QuestEngine.lua")

local logger = addon.Logger:NewLogger("Engine", addon.LogLevel.info)

addon.QuestEngine = {}

-- This will be replaced with a new table when the compiler loads
local objectives = {}

addon.QuestStatus = {
  Invited = "Invited",
  Declined = "Declined",
  Active = "Active",
  Failed = "Failed",
  Abandoned = "Abandoned",
  Completed = "Completed",
  Archived = "Archived",
}
local status = addon.QuestStatus

------------------------
-- Predefined Methods --
------------------------

local function objective_HasCondition(obj, name)
  return obj.conditions and obj.conditions[name] and true
end

local function objective_GetConditionValue(obj, name)
  if obj.conditions then
    return obj.conditions[name]
  end
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

---------------------------------------------------
-- Private functions: Quest objective evaluation --
---------------------------------------------------

local function evaluateObjective(objective, obj, ...)
  local ok, beforeResult, checkResult, afterResult
  if objective.scripts and objective.scripts.BeforeCheckConditions then
    ok, beforeResult = pcall(objective.scripts.BeforeCheckConditions, obj, ...)
    if not(ok) then
      logger:Error("Error during BeforeCheckConditions for '", obj.id, "':", beforeResult)
      return
    elseif beforeResult == false then
      return
    end
  end

  -- CheckCondition is expected to return a boolean value only:
  -- true if the condition was met, false otherwise
  local anyFailed
  for name, val in pairs(obj.conditions) do
    local condition = objective._paramsByName[name]
    if condition.scripts and condition.scripts.CheckCondition then
      -- CheckCondition receives 2 args: The obj being evaluated, and the value(s) for this condition
      ok, checkResult = pcall(condition.scripts.CheckCondition, obj, val)
      if not(ok) then
        logger:Error("Error evaluating condition '", name,"' for '", obj.id, "':", checkResult)
        return
      elseif checkResult ~= true  then
        -- If any result was not true, keep evaluating conditions, but set checkResult to false when it's all done
        logger:Trace("Condition '"..name.."' evaluated:", checkResult)
        anyFailed = true
      end
    end
  end
  if anyFailed then
    checkResult = false
  end

  -- AfterCheckConditions may take the result from CheckCondition and make a final ruling by
  -- returning either a boolean or a number to represent objective progress
  if objective.scripts and objective.scripts.AfterCheckConditions then
    ok, afterResult = addon:catch(objective.scripts.AfterCheckConditions, obj, checkResult, ...)
    if not(ok) then
      logger:Error("Error during AfterCheckConditions for '", obj.id, "':", afterResult)
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

local function wrapObjectiveHandler(objective)
  -- Given an arbitrary list of game event args, handle them as follows
  return function(...)
    local numActive = addon:tlen(objective._active)
    if numActive < 1 then return end

    logger:Debug("Evaluating objective:", objective.name, "("..addon:tlen(objective._active).." active)")
    -- logger:Table(objective._active)
    -- Completed objectives will be tracked and removed from the list
    local completed = {}
    local anychanged = false

    -- For each active instance of this objective
    for id, obj in pairs(objective._active) do
      if obj.progress >= obj.goal then
        -- The objective is already completed, nothing to do
        completed[id] = obj
      else
        local result = evaluateObjective(objective, obj, ...) or 0
        logger:Debug("    Result:", result)

        if result > 0 then
          anychanged = true
          obj.progress = obj.progress + result
          local quest = obj._quest

          -- Sanity checks: progress must be >= 0, and progress must be an integer
          obj.progress = math.max(math.floor(obj.progress), 0)

          addon.AppEvents:Publish("ObjectiveUpdated", obj)

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
              addon.QuestLog:SetQuestStatus(quest.id, status.Completed)
            end
          end
        end
      end
    end

    for id, _ in pairs(completed) do
      -- Stop trying to update that objective on subsequent game events
      objective._active[id] = nil
    end

    if anychanged then
      addon.QuestLog:Save()
    end
  end
end

----------------------------------
-- Building and Tracking Quests --
----------------------------------

function addon.QuestEngine:Build(quest)
  if quest._built then return end
  quest.name = quest.name or error("Failed to create quest: quest name is required")

  quest.objectives = quest.objectives or {}

  for _, obj in pairs(quest.objectives) do
    obj.name = obj.name or error("Failed to create quest: objective name is required")
    obj._parent = objectives[obj.name] or error("Failed to create quest: '"..obj.name.."' is not a valid objective")
    obj._quest = quest -- Add reference back to this obj's quest
    obj._tempdata = {}

    obj.id = obj.id or addon:CreateID("objective-"..obj.name.."-%i")
    obj.progress = obj.progress or 0
    obj.goal = obj.goal or 1
    obj.conditions = obj.conditions or {}
    obj.metadata = obj.metadata or {}

    -- Add predefined methods here
    obj.HasCondition = objective_HasCondition
    obj.GetConditionValue = objective_GetConditionValue
    obj.GetMetadata = objective_GetMetadata
    obj.SetMetadata = objective_SetMetadata

    for name, _ in pairs(obj.conditions) do
      local condition = obj._parent._paramsByName[name]
      if not condition then
        error("Failed to create quest: '"..name.."' is not a valid condition for objective '"..obj._parent.name.."'")
      end
    end
  end

  quest._built = true
  return quest
end

local function startTracking(quest)
  -- All active instances of a created objective are stored together
  -- so that they can be quickly evaluated together
  for _, obj in pairs(quest.objectives) do
    obj._parent._active[obj.id] = obj
  end
  addon.AppEvents:Publish("QuestTrackingStarted", quest)
end

local function stopTracking(quest)
  for _, obj in pairs(quest.objectives) do
    obj._parent._active[obj.id] = nil
  end
  addon.AppEvents:Publish("QuestTrackingStopped", quest)
end

local function setTracking(quest)
  if quest.status == status.Active then
    -- If start tracking fails, let it throw an error
    startTracking(quest)
  else
    -- If stop tracking fails, simply log the error
    addon:catch(stopTracking, quest)
  end
end

addon.AppEvents:Subscribe("QuestAdded", setTracking)
addon.AppEvents:Subscribe("QuestStatusChanged", setTracking)
addon.AppEvents:Subscribe("QuestDeleted", stopTracking)

addon.AppEvents:Subscribe("QuestLogLoaded", function(quests)
  for _, q in pairs(quests) do
    addon.QuestEngine:Build(q)
    setTracking(q)
  end
  addon.AppEvents:Publish("QuestLogBuilt", quests)
end)

addon.AppEvents:Subscribe("QuestLogReset", function()
  for _, objective in pairs(objectives) do
    objective._active = {}
  end
end)

addon.AppEvents:Subscribe("CompilerLoaded", function(qsObjectives)
  -- Ensure everything can be setup, then wire up objectives into the engine
  objectives = qsObjectives
  for _, objective in pairs(objectives) do
    objective._active = {} -- Every active instance of this objective will be tracked
    addon.QuestEvents:Subscribe(objective.name, wrapObjectiveHandler(objective))
  end
  logger:Debug("QuestEngine loaded OK!")
  addon.AppEvents:Publish("EngineLoaded")
end)