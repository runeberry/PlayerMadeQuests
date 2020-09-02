local _, addon = ...
local logger = addon.Logger:NewLogger("Checkpoint")
local assertf, errorf = addon.assertf, addon.errorf

local parameters = addon.QuestEngine.definitions.parameters
local conditions = addon.QuestEngine.definitions.conditions

local function evaluateConditions(cp)
  if not cp.conditions or addon:tlen(cp.conditions) == 0 then
    -- If there are no conditions to evaluate, then all conditions are met
    return true
  end

  -- Step 2: Run BeforeEvaluate on each condition
  local excludeFromEvaluate = {}
  for name, val in pairs(cp.conditions) do
    local condition = conditions[name]
    if condition.BeforeEvaluate then
      -- condition:BeforeEvaluate(val, cp)
      local ok, result = pcall(condition.BeforeEvaluate, condition, val, cp)
      if not ok then
        logger:Error("Error during Condition:BeforeEvaluate() for %s: %s", name, result)
        return false
      elseif result == false then
        -- If BeforeEvaluate returns explicitly false, then Evalute and AfterEvalute will not
        -- be performed for this occurrence of the condition
        excludeFromEvaluate[name] = true
      end
    end
  end

  -- Step 3: Run Evaluate on each condition
  local totalEvaluateResult = true
  for name, val in pairs(cp.conditions) do
    local condition = conditions[name]
    if condition.Evaluate and not excludeFromEvaluate[name] then
      -- condition:Evaluate(val, cp)
      local ok, result = pcall(condition.Evaluate, condition, val, cp)
      if not ok then
        logger:Error("Error during Condition:Evaluate() for %s: %s", name, result)
        return false
      elseif not result then
        -- The total condition evaluation fails if any Evaluate step returns false or nil
        totalEvaluateResult = false
      end
    end
  end

  -- Step 4: Run AfterEvaluate on each condition
  for name, val in pairs(cp.conditions) do
    local condition = conditions[name]
    if condition.AfterEvaluate and not excludeFromEvaluate[name] then
      -- condition:AfterEvaluate(result, val, cp)
      local ok, result = pcall(condition.AfterEvaluate, condition, totalEvaluateResult, val, cp)
      if not ok then
        logger:Error("Error during Condition:AfterEvaluate() for %s: %s", name, result)
        return false
      elseif result == false then
        -- The total condition evaluation fails if any AfterEvaluate step returns explicitly false
        totalEvaluateResult = false
      end
    end
  end

  return totalEvaluateResult
end

--- These are all of the recognized options for adding a parameter/condition to a checkpoint,
--- along with the value that will be used for each when they are not specified.
local defaultParameterOptions = {
  required = false,
  defaultValue = nil,
  alias = nil,
}

local methods = {
  --- Adds a parameter that can be used with any instance of this checkpoint.
  --- For example: "goal" or "text".
  ["AddParameter"] = function(self, name, options)
    if options then
      options = addon:MergeTable(defaultParameterOptions, options)
    else
      options = addon:CopyTable(defaultParameterOptions)
    end
    options.name = name
    self.parameters[name] = options
  end,
  --- Adds a condition that is evaluated when a checkpoint is evaluated.
  --- For example, "item" or "target".
  ["AddCondition"] = function(self, name, options)
    self:AddParameter(name, options)
    self.conditions[name] = self.parameters[name]
  end,
  ["AddShorthandForm"] = function(self, ...)
    self.shorthandAssignments = { ... }
  end,
  ["Parse"] = function(self, rawValue)
    -- If this checkpoint has a possible shorthand form,
    -- then parse that into a standardized form before proceeding
    if self.shorthandAssignments and #rawValue > 0 then
      rawValue = addon:AssignShorthandArgs(rawValue, self.shorthandAssignments)
    end

    local cp = {
      id = addon:CreateID("checkpoint-"..self.name.."-%i"),
      name = self.name,
      parameters = {},
      conditions = {},
    }

    logger:Debug("Parsing checkpoint '%s' (%s)", cp.name, cp.id)

    -- (jb, 9/1/20) Important caveat!
    -- On the checkpoint template (self), every condition is also in the list of parameters
    -- But on an instance of the checkpoint (cp), parameters and conditions are mutually exclusive
    -- I'm not sure which is the best approach, but this should be probably be changed for consistency in the future.

    local assignedConditions = {}

    for cond, opts in pairs(self.conditions) do
      -- Check the primary condition name first, otherwise fall back on an alias if specified
      local v = rawValue[cond]
      rawValue[cond] = nil
      if v == nil and opts.alias then
        v = rawValue[opts.alias]
        rawValue[opts.alias] = nil
      end
      local condition = conditions[cond]
      logger:Trace("  Condition: %s = %s", cond, tostring(v))
      v = condition:Parse(v, opts)
      cp.conditions[cond] = v
      -- Mark as assigned so that it doesn't get re-processed as a parameter
      assignedConditions[cond] = true
    end

    for param, opts in pairs(self.parameters) do
      -- Only evaluate values that have not already been assigned to conditions
      if not assignedConditions[param] then
        -- Check the primary parameter name first, otherwise fall back on an alias if specified
        local v = rawValue[param]
        rawValue[param] = nil
        if v == nil and opts.alias then
          v = rawValue[opts.alias]
          rawValue[opts.alias] = nil
        end
        local parameter = parameters[param]
        logger:Trace("  Parameter: %s = %s", param, tostring(v))
        v = parameter:Parse(v, opts)
        cp.parameters[param] = v
      end
    end

    -- If there are any values left unassigned in the rawValue, then some unexpected values are present
    for k, _ in pairs(rawValue) do
      errorf("'%s' is not a supported parameter on checkpoint '%s'", k, self.name)
    end

    return cp
  end,
  ["Evaluate"] = function(self, cp)
    -- Step 1: Run BeforeEvaluate on the checkpoint
    if self.BeforeEvaluate then
      local ok, result = pcall(self.BeforeEvaluate, self, cp)
      if not ok then
        logger:Error("Error during Checkpoint:BeforeEvaluate() for %s: %s", cp.name, result)
        return
      elseif result == false then
        -- If BeforeEvaluate returns explicitly false, condition evaluation will be skipped entirely
        return
      end
    end

    local evaluationResult = evaluateConditions(cp)

    -- Step 5: Run AfterEvaluate on the checkpoint
    if self.AfterEvaluate then
      local ok, result = pcall(self.AfterEvaluate, self, evaluationResult, cp)
      if not ok then
        logger:Error("Error during Checkpoint:AfterEvaluate() for %s: %s", cp.name, result)
        return
      elseif result ~= nil then
        -- AfterEvaluate can transform the condition evaluation result from a boolean
        -- to whatever form suits this checkpoint
        evaluationResult = result
      end
    end

    return evaluationResult
  end,
  -- Optional hooks for any instance of a checkpoint.
  -- Define these functions in the file in which the checkpoint is created.
  ["OnParse"] = nil,
  ["BeforeEvaluate"] = nil,
  ["AfterEvaluate"] = nil,
}

function addon.QuestEngine:NewCheckpoint(name)
  local checkpoint = {
    name = name,
    logger = logger,
    parameters = {},
    conditions = {},
  }

  for fname, fn in pairs(methods) do
    checkpoint[fname] = fn
  end

  addon.QuestEngine:AddDefinition("checkpoints", name, checkpoint)
  return checkpoint
end