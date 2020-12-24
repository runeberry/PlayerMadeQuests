local _, addon = ...
local tokens = addon.QuestScriptTokens

local methods = {
  ["AddAppEvent"] = function(self, name, filter)
    self.events[#self.events+1] = { name = name, filter = filter, broker = addon.AppEvents }
  end,
  ["AddCombatLogEvent"] = function(self, name, filter)
    self.events[#self.events+1] = { name = name, filter = filter, broker = addon.CombatLogEvents }
  end,
  ["AddGameEvent"] = function(self, name, filter)
    self.events[#self.events+1] = { name = name, filter = filter, broker = addon.GameEvents }
  end,
  ["EvaluateOnQuestStart"] = function(self, flag)
    if flag == nil then flag = true end
    self.onQuestStart = flag
  end,
  ["Init"] = function(self)
    -- Objectives can be triggered in a few different ways:
    -- 1. Publish a QuestEvent to the name of the objective
    addon.QuestEvents:Subscribe(self.name, function()
      self:EvaluateAllActive()
    end)
    -- 2. If specified, an objective can be evaluated when a quest is started
    if self.onQuestStart then
      self.events[#self.events+1] = { name = "QuestTrackingStarted", broker = addon.AppEvents }
    end
    -- 3. Subscribe the objective to a specific event within the addon
    for _, ev in ipairs(self.events) do
      ev.broker:Subscribe(ev.name, function(...)
        if ev.filter then
          if not ev.filter(...) then return end
        end
        addon.QuestEvents:Publish(self.name)
      end)
    end
  end,
  ["Parse"] = function(self, objRaw)
    local obj = self:_baseParse(objRaw)
    obj.progress = 0
    -- Goal needs to be defaulted to 1 here because even objectives that don't allow goal parameters
    -- still need to have their default goal set to 1
    obj.goal = obj.parameters[tokens.PARAM_GOAL] or 1
    obj.parameters[tokens.PARAM_GOAL] = nil
    -- If there are no other parameters, then remove the parameters table entirely to save space
    if addon:tlen(obj.parameters) == 0 then
      obj.parameters = nil
    end
    return obj
  end,
  ["Evaluate"] = function(self, obj)
    self.logger:Debug("===== Evaluating objective: %s =====", obj.name)
    local result = self:_baseEvaluate(obj)

    -- Coerce non-numeric results to a goal progress number
    if result == true then
      -- A boolean result of true will advance the objective by 1
      result = 1
    elseif type(result) ~= "number" then
      -- False, nil, or non-numeric values will result in no objective progress
      result = 0
    end

    if result ~= 0 then
      -- Sanity checks:
      --   * progress must be an integer
      --   * progress must be >= 0
      --   * progress must be <= goal
      local newProgress = obj.progress + result
      newProgress = math.floor(newProgress)
      newProgress = math.max(newProgress, 0)
      newProgress = math.min(newProgress, obj.goal)

      obj.progress = newProgress

      addon.AppEvents:Publish("ObjectiveUpdated", obj)
      if obj.progress >= obj.goal then
        addon.AppEvents:Publish("ObjectiveCompleted", obj)
      end
    end

    self.logger:Trace("===== Evaluated objective: %s (%s) =====", obj.name, tostring(result))
    return result
  end,
  --- Runs Evaluate() on all active instances of this objective.
  ["EvaluateAllActive"] = function(self)
    local numActive = addon:tlen(self.active)
    if numActive < 1 then
      self.logger:Trace("No active objectives for: %s", self.name)
      return
    end

    self.logger:Debug("***** Evaluating objectives: %s (%i active) *****", self.name, addon:tlen(self.active))
    -- logger:Table(objective.active)
    -- Completed objectives will be tracked and removed from the list
    local completed = {}

    -- For each active instance of this objective
    for id, obj in pairs(self.active) do
      if obj.progress >= obj.goal then
        -- The objective is already completed, nothing to do but stop tracking it
        completed[id] = obj
      else
        self:Evaluate(obj)
        if obj.progress >= obj.goal then
          -- Now the objective is completed, stop tracking it
          completed[id] = obj
        end
      end
    end

    for id, _ in pairs(completed) do
      -- Stop trying to update completed objectives on subsequent game events
      self.active[id] = nil
    end

    self.logger:Trace("***** Finished evaluating objectives: %s *****", self.name)
  end,
}

function addon.QuestEngine:NewObjective(name)
  local objective = self:NewCheckpoint(name)
  -- Objective is like a superclass of Checkpoint
  -- It still calls the base methods, but adds a little extra sugar on top
  objective._baseParse = objective.Parse
  objective._baseEvaluate = objective.Evaluate

  objective.active = {}
  objective.events = {}
  objective.onQuestStart = false

  -- OK to overwrite base methods
  addon:ApplyMethods(objective, methods, true)

  addon.QuestEngine:AddDefinition("objectives", name, objective)
  return objective
end