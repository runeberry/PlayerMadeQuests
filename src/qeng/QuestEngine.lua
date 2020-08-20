local _, addon = ...
local tokens = addon.QuestScriptTokens
local QuestLog, QuestStatus
addon:onload(function()
  QuestLog, QuestStatus = addon.QuestLog, addon.QuestStatus
end)

local logger = addon.Logger:NewLogger("Engine", addon.LogLevel.info)
local objectiveLogger = addon.Logger:NewLogger("Objectives", addon.LogLevel.info)
objectiveLogger.pass = addon:Colorize("green", "[P] ")
objectiveLogger.fail = addon:Colorize("red", "[F] ")

addon.QuestEngine = {
  ObjectiveLogger = objectiveLogger
}

local objectivesByName = {}
local isEngineLoaded = false
local isQuestDataLoaded = false

---------------------------------------------------
-- Private functions: Quest objective evaluation --
---------------------------------------------------

local function evaluateObjective(objective, obj, ...)
  local ok, beforeResult, checkResult, afterResult
  objectiveLogger:Debug("=== Evaluating objective \"%s\"", obj.name)

  if objective.scripts and objective.scripts[tokens.METHOD_PRE_EVAL] then
    -- Determine if the objective as a whole should be evaluated
    ok, beforeResult = pcall(objective.scripts[tokens.METHOD_PRE_EVAL], obj, ...)
    if not ok then
      objectiveLogger:Error("Error during pre-evaluation for \"%s\": %s", obj.id, beforeResult)
      return
    elseif beforeResult == false then
      -- If the objective's pre-condition returns boolean false, then do not continue evaluating the objective
      objectiveLogger:Debug("    Pre-evaluation returned false for %s. Terminating early.", obj.id)
      return
    end
  end

  -- Evaluation is expected to return a boolean value only:
  -- true if the condition was met, false otherwise
  local anyFailed
  local conditionPostEvals = {}
  for name, val in pairs(obj.conditions) do
    local condition = objective.params[name]
    if condition.scripts and condition.scripts[tokens.METHOD_EVAL] then
      -- Evaluation receives 2 args: The obj being evaluated, and the value(s) for this condition
      ok, checkResult = pcall(condition.scripts[tokens.METHOD_EVAL], obj, val)
      if not ok then
        objectiveLogger:Error("Error evaluating condition %s for %s: %s", name, obj.id, checkResult)
        return
      elseif checkResult ~= true then
        -- If any result was not true, keep evaluating conditions, but set checkResult to false when it's all done
        -- We keep evaluating because there might be side-effects from other conditions that are still required (not ideal, but oh well)
        anyFailed = true
      end
      if condition.scripts[tokens.METHOD_POST_EVAL] then
        -- If the condition has a post-evaluation method, reference it here so we can run it
        -- After the objective's post-evaluation method
        conditionPostEvals[#conditionPostEvals+1] = {
          script = condition.scripts[tokens.METHOD_POST_EVAL],
          name = name,
          val = val,
        }
      end
    end
  end
  if anyFailed then
    checkResult = false
  end

  -- Post-evaluation may take the result from evaluation and make a final ruling by
  -- returning either a boolean or a number to represent objective progress
  if objective.scripts and objective.scripts[tokens.METHOD_POST_EVAL] then
    ok, afterResult = addon:catch(objective.scripts[tokens.METHOD_POST_EVAL], obj, checkResult, ...)
    if not ok then
      objectiveLogger:Error("Error during post-evaluation for \"%s\": %s", obj.id, afterResult)
      return
    elseif afterResult ~= nil then
      -- If the post-evaluation returns a value, then that value will override the result of evaluation
      checkResult = afterResult
      objectiveLogger:Trace("    Post-evaluation overriding result with: %i", checkResult)
    end
  end

  -- If there were any condition-level post-evaluation methods, run them now
  local err
  for _, postEval in ipairs(conditionPostEvals) do
    ok, err = addon:catch(postEval.script, obj, checkResult, postEval.val)
    if not ok then
      objectiveLogger:Error("Error during post-evaluation for \"%s\": %s", postEval.name, err)
      -- Continue running, because the method has no effect on the result
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

  objectiveLogger:Trace("=== Evaluated \"%s\": %s", obj.name, checkResult)
  return checkResult
end

local function updateQuestObjectiveProgress(obj)
  local quest = QuestLog:FindByID(obj.questId)
  if not quest then
    logger:Warn("Unable to update quest objective: no quest by id %s", obj.questId)
    return
  elseif quest.status ~= QuestStatus.Active then
    logger:Warn("Unable to update quest objective: quest \"%s\" is not Active (%s)", quest.name, quest.status)
    return
  end

  local qobj
  for _, qo in ipairs(quest.objectives) do
    if qo.id == obj.id then
      qobj = qo
      break
    end
  end
  if not qobj then
    logger:Warn("Unable to update quest objective: no objective on quest \"%s\" with id %s", quest.name, obj.id)
    return
  end

  qobj.progress = obj.progress
  QuestLog:Save(quest)

  local isObjectiveCompleted, isQuestFinished
  -- objective is considered completed if progress is >= goal
  if obj.progress >= obj.goal then
    -- quest is only considered completed if all objectives would be considered completed
    isObjectiveCompleted = true
    isQuestFinished = true
    for _, qo in pairs(quest.objectives) do
      if qo.progress < qo.goal then
        isQuestFinished = false
        break
      end
    end
  end

  if isQuestFinished then
    quest.status = QuestStatus.Finished
  end
  QuestLog:Save(quest)

  addon.AppEvents:Publish("ObjectiveUpdated", obj)
  if isObjectiveCompleted then
    addon.AppEvents:Publish("ObjectiveCompleted", obj)
  end

  return isObjectiveCompleted, isQuestFinished
end

local function wrapObjectiveHandler(objective)
  -- Given an arbitrary list of game event args, handle them as follows
  return function(...)
    local numActive = addon:tlen(objective._active)
    if numActive < 1 then
      objectiveLogger:Trace("No active objectives for: %s", objective.name)
      return
    end

    objectiveLogger:Debug("***** Evaluating objectives: %s (%i active)", objective.name, addon:tlen(objective._active))
    -- logger:Table(objective._active)
    -- Completed objectives will be tracked and removed from the list
    local completed = {}

    -- For each active instance of this objective
    for id, obj in pairs(objective._active) do
      if obj.progress >= obj.goal then
        -- The objective is already completed, nothing to do
        completed[id] = obj
      else
        local result = evaluateObjective(objective, obj, ...) or 0
        logger:Debug("    Result: %i", result)

        if result > 0 then
          obj.progress = obj.progress + result
          -- Sanity checks: progress must be >= 0, and progress must be an integer
          obj.progress = math.max(math.floor(obj.progress), 0)
          local isObjectiveCompleted = updateQuestObjectiveProgress(obj)
          if isObjectiveCompleted then
            -- Mark objective for removal from further checks
            completed[id] = obj
          end
        end
      end
    end

    for id, _ in pairs(completed) do
      -- Stop trying to update that objective on subsequent game events
      objective._active[id] = nil
    end

    objectiveLogger:Trace("***** Finished evaluating objectives: %s", objective.name)
  end
end

local function evaluateStartComplete(section, token)
  if not section or not section.conditions then
    -- Nothing to evaluate, the quest can be started/completed
    return true
  end

  logger:Debug("Evaluating %s condition...", token)
  local objective = addon.QuestScript[token] -- "start" or "complete"
  local result = evaluateObjective(objective, section)
  logger:Debug("    Result: %s", result)
  return result > 0
end

--------------------
-- Public methods --
--------------------

function addon.QuestEngine:Validate(quest)
  assert(type(quest.questId) == "string" and quest.questId ~= "", "questId is required")
  assert(type(quest.name) == "string" and quest.name ~= "", "quest name is required")
  assert(type(quest.addonVersion) == "number", "quest addonVersion is required")
  assert(type(quest.objectives) == "table", "quest objectives must be defined")

  for _, obj in ipairs(quest.objectives) do
    assert(type(obj.id) == "string" and obj.id ~= "", "objective id is required")
    assert(type(obj.name) == "string" and obj.name ~= "", "objective name is required")

    local objTemplate = objectivesByName[obj.name]
    assert(objTemplate, addon:Enquote(obj.name).." is not a valid objective")

    assert(type(obj.goal) == "number" and obj.goal > 0, addon:Enquote(obj.name).." objective must have a goal > 0")
    assert(type(obj.progress) == "number" and obj.progress >= 0, addon:Enquote(obj.name).." objective must have progress >= 0")

    assert(type(obj.conditions) == "table", addon:Enquote(obj.name).." must have conditions defined")
    for condName, _ in pairs(obj.conditions) do
      local condition = objTemplate.params[condName]
      assert(condition, addon:Enquote(condName).." is not a valid condition for objective "..addon:Enquote(objTemplate.name))
    end
  end
end

function addon.QuestEngine:EvaluateStart(quest)
  return evaluateStartComplete(quest.start, tokens.CMD_START)
end

function addon.QuestEngine:EvaluateComplete(quest)
  return evaluateStartComplete(quest.complete, tokens.CMD_COMPLETE)
end

function addon.QuestEngine:EvaluateRecommendations(quest)
  return addon.QuestScript[tokens.CMD_REC].scripts[tokens.METHOD_EVAL](quest)
end

function addon.QuestEngine:EvaluateRequirements(quest)
  return addon.QuestScript[tokens.CMD_REQ].scripts[tokens.METHOD_EVAL](quest)
end

-------------------------
-- Event Subscriptions --
-------------------------

local function startTracking(quest)
  -- sanity check: validate quest before tracking it
  addon.QuestEngine:Validate(quest)

  local didStartTracking = false
  for _, obj in pairs(quest.objectives) do
    -- All active instances of a created objective are stored together
    -- so that they can be quickly evaluated together
    if not objectivesByName[obj.name]._active[obj.id] then
      objectivesByName[obj.name]._active[obj.id] = obj
      didStartTracking = true
    end
  end
  if didStartTracking then
    addon.AppEvents:Publish("QuestTrackingStarted", quest)
  end
  logger:Trace("Started tracking quest: %s", quest.name)
end

local function stopTracking(quest)
  local didStopTracking = false
  for _, obj in pairs(quest.objectives) do
    if objectivesByName[obj.name]._active[obj.id] then
      objectivesByName[obj.name]._active[obj.id] = nil
      didStopTracking = true
    end
  end
  if didStopTracking then
    addon.AppEvents:Publish("QuestTrackingStopped", quest)
  end
  logger:Trace("Stopped tracking quest: %s", quest.name)
end

local function setTracking(quest)
  if quest.status == QuestStatus.Active then
    -- If start tracking fails, let it throw an error
    startTracking(quest)
  else
    -- If stop tracking fails, simply log the error
    addon:catch(stopTracking, quest)
  end
end

local function startTrackingQuestLog()
  local quests = QuestLog:FindByQuery(function(q) return q.status == QuestStatus.Active end)
  for _, q in pairs(quests) do
    local ok, err = pcall(startTracking, q)
    if not ok then
      logger:Error("Failed to start quest tracking for quest \"%s\": %s", q.name, err)
    end
  end
  addon.AppEvents:Publish("QuestLogBuilt", quests)
end

addon.AppEvents:Subscribe("QuestAdded", setTracking)
addon.AppEvents:Subscribe("QuestStatusChanged", function(q)
  if q.status == QuestStatus.Active then
    -- Reset quest objective progress when the quest enters the Active status
    for _, obj in ipairs(q.objectives) do
      obj.progress = 0
    end
    QuestLog:Save(q)
  end
  setTracking(q)
end)
addon.AppEvents:Subscribe("QuestDeleted", stopTracking)

addon.AppEvents:Subscribe("QuestDataLoaded", function()
  if isEngineLoaded then
    startTrackingQuestLog()
  end
  isQuestDataLoaded = true
end)

addon.AppEvents:Subscribe("QuestDataReset", function()
  for _, objective in pairs(objectivesByName) do
    objective._active = {}
  end
  logger:Trace("Stopped tracking all quests")
end)

addon.AppEvents:Subscribe("QuestScriptLoaded", function()
  -- Ensure everything can be setup, then wire up objectives into the engine
  local queryQuestEvents = function(cmd) return cmd.questEvent end
  objectivesByName = addon.QuestScriptCompiler:Find(queryQuestEvents)
  for _, objective in pairs(objectivesByName) do
    objective._active = {} -- Every active instance of this objective will be tracked
    addon.QuestEvents:Subscribe(objective.name, wrapObjectiveHandler(objective))
  end
  logger:Debug("QuestEngine loaded OK!")
  if isQuestDataLoaded then
    startTrackingQuestLog()
  end
  isEngineLoaded = true
  addon.AppEvents:Publish("EngineLoaded")
end)