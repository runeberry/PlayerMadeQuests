local _, addon = ...
addon:traceFile("QuestEngine.lua")

local logger = addon.Logger:NewLogger("Engine", addon.LogLevel.info)

addon.QuestEngine = {}

local objectivesByName = {}
local questsByObjective = {}

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

---------------------------------------------------
-- Private functions: Quest objective evaluation --
---------------------------------------------------

local function evaluateObjective(objective, obj, ...)
  local ok, beforeResult, checkResult, afterResult
  logger:Trace("Evaluating objective", addon:Enquote(obj.name), addon:Enquote(obj.id, "()"))

  if objective.scripts and objective.scripts.BeforeCheckConditions then
    -- Determine if the objective as a whole should be evaluated
    ok, beforeResult = pcall(objective.scripts.BeforeCheckConditions, obj, ...)
    if not ok then
      logger:Error("Error during BeforeCheckConditions for", addon:Enquote(obj.id), ":", beforeResult)
      return
    elseif beforeResult == false then
      -- If the objective's pre-condition returns boolean false, then do not continue evaluating the objective
      logger:Trace("BeforeCheckConditions evaluated false for", obj.id..". Terminating early.")
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
      logger:Trace("    Condition", addon:Enquote(name), "evaluated:", checkResult)
      if not ok then
        logger:Error("Error evaluating condition", addon:Enquote(name), "for", addon:Enquote(obj.id), ":", checkResult)
        return
      elseif checkResult ~= true then
        -- If any result was not true, keep evaluating conditions, but set checkResult to false when it's all done
        -- We keep evaluating because there might be side-effects from other conditions that are still required (not ideal, but oh well)
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
      logger:Error("Error during AfterCheckConditions for", addon:Enquote(obj.id), ":", afterResult)
      return
    elseif afterResult ~= nil then
      -- If the After function returns a value, then that value will override the result of CheckCondition
      checkResult = afterResult
      logger:Trace("    AfterCheckConditions overriding result with:", checkResult)
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

  logger:Trace(obj.name, "evaluated:", checkResult)
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
          local quest = questsByObjective[obj.id]

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
              addon.QuestLog:SetQuestStatus(quest.questId, status.Completed)
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

function addon.QuestEngine:Validate(quest)
  assert(not quest.id, "quest.id should no longer be used")
  assert(type(quest.questId) == "string" and quest.questId ~= "", "questId is required")
  assert(type(quest.name) == "string" and quest.name ~= "", "quest name is required")
  assert(type(quest.objectives) == "table", "quest objectives must be defined")

  for _, obj in ipairs(quest.objectives) do
    assert(type(obj.id) == "string" and obj.id ~= "", "objective id is required")
    assert(type(obj.name) == "string" and obj.name ~= "", "objective name is required")

    local objTemplate = objectivesByName[obj.name]
    assert(objTemplate, addon:Enquote(obj.name).." is not a valid objective")

    assert(type(obj.goal) == "number" and obj.goal > 0, addon:Enquote(obj.name).." objective must have a goal > 0")
    assert(type(obj.progress) == "number" and obj.progress >= 0, addon:Enquote(obj.progress).." objective must have progress >= 0")

    assert(type(obj.conditions) == "table", addon:Enquote(obj.name).." must have conditions defined")
    for condName, _ in pairs(obj.conditions) do
      local condition = objTemplate._paramsByName[condName]
      assert(condition, addon:Enquote(condName).." is not a valid condition for objective "..addon:Enquote(objTemplate.name))
    end
  end
end

local function startTracking(quest)
  -- All active instances of a created objective are stored together
  -- so that they can be quickly evaluated together
  for _, obj in pairs(quest.objectives) do
    questsByObjective[obj.id] = quest
    objectivesByName[obj.name]._active[obj.id] = obj
  end
  addon.AppEvents:Publish("QuestTrackingStarted", quest)
end

local function stopTracking(quest)
  for _, obj in pairs(quest.objectives) do
    questsByObjective[obj.id] = nil
    objectivesByName[obj.name]._active[obj.id] = nil
  end
  addon.AppEvents:Publish("QuestTrackingStopped", quest)
end

local function setTracking(quest)
  -- sanity check: validate quest before tracking it
  addon.QuestEngine:Validate(quest)
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
    local ok, err = pcall(setTracking, q)
    if ok then
      setTracking(q)
    else
      logger:Error("Failed to set quest tracking:", err)
    end
  end
  addon.AppEvents:Publish("QuestLogBuilt", quests)
end)

addon.AppEvents:Subscribe("QuestLogReset", function()
  for _, objective in pairs(objectivesByName) do
    objective._active = {}
  end
end)

addon.AppEvents:Subscribe("CompilerLoaded", function(qsObjectives)
  -- Ensure everything can be setup, then wire up objectives into the engine
  objectivesByName = addon:CopyTable(qsObjectives)
  for _, objective in pairs(objectivesByName) do
    objective._active = {} -- Every active instance of this objective will be tracked
    addon.QuestEvents:Subscribe(objective.name, wrapObjectiveHandler(objective))
  end
  logger:Debug("QuestEngine loaded OK!")
  addon.AppEvents:Publish("EngineLoaded")
end)