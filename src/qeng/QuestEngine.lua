local _, addon = ...
addon:traceFile("QuestEngine.lua")

addon.QuestEngine = {}

local rules = {}
local conditions = {}
local cleanNamePattern = "^[%l%d]+$"

local function objective_HasCondition(obj, name)
  return obj.conditions and obj.conditions[name] and true
end

local function objective_SetMetadata(obj, name, value, persistent)
  if persistent then
    -- These values will be written to SavedVariables
    obj.metadata[name] = value
  else
    -- These values will not be saved. Use for non-serializable data.
    obj.tempdata[name] = value
  end
end

local function objective_GetMetadata(obj, name)
  if obj.metadata[name] ~= nil then
    return obj.metadata[name]
  elseif obj.tempdata[name] ~= nil then
    return obj.tempdata[name]
  end
  return nil
end

local function condition_CheckCondition(cond, obj, args)
  addon:warn("No CheckCondition method is defined for condition:", cond.name)
end

-- todo: move this somewhere else
local function getConditionParameterText(cond, val)
  if type(val) == "string" then
    return val
  elseif type(val) == "table" then
    if #val == 1 then
      for v in val do
        return v
      end
    elseif #val > 1 then
      local ret = ""
      local i = 1
      for v in val do
        if i == #val then
          return ret.." or "..v
        else
          ret = ret..", "..v
        end
        i = i + 1
      end
    end
  end
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
    -- Completed objectives will be tracked and removed from the list
    local completed = {}

    -- For each objective that is backed by this rule
    for i, obj in ipairs(rule.objectives) do
      if obj.progress >= obj.goal then
        -- The objective is already completed, nothing to do
        table.insert(completed, i)
      else
        local result = evaluateObjective(rule, obj, ...)

        local changed = false
        if result == true then
          -- If the handler returns true, then objective progress is advanced by 1
          obj.progress = obj.progress + 1
          changed = true
        elseif type(result) == "number" then
          -- If it returns a number, then objective progress is advanced by that amount
          -- Note that this can be negative to "undo" objective progress
          obj.progress = obj.progress + result
          changed = true
        end

        if changed then
          -- Sanity checks: progress must be >= 0, and progress must be an integer
          obj.progress = math.max(math.floor(obj.progress), 0)

          addon.AppEvents:Publish("ObjectiveUpdated", obj)
          addon.AppEvents:Publish("QuestUpdated", obj.quest)

          if obj.progress >= obj.goal then
            -- Mark objective for removal from further checks
            table.insert(completed, i)
            addon.AppEvents:Publish("ObjectiveCompleted", obj)

            local questCompleted = true
            for _, qobj in pairs(obj.quest.objectives) do
              if qobj.progress < qobj.goal then
                questCompleted = false
                break
              end
            end
            if questCompleted then
              addon.AppEvents:Publish("QuestCompleted", obj.quest)
            end
          end
        end
      end
    end

    for _, i in pairs(completed) do
      -- Stop trying to update that objective on subsequent game events
      table.remove(rule.objectives, i)
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
    name = name,
    CheckCondition = condition_CheckCondition
  }

  conditions[name] = condition
  return condition
end

function addon.QuestEngine:IsValidRule(name)
  return rules[name] ~= nil
end

function addon.QuestEngine:ActivateQuest(quest)
  for _, obj in pairs(quest.objectives) do
    obj.rule = rules[obj.name] -- Rule is validated on script compilation
    obj.quest = quest -- Add reference back to this obj's quest
    if obj.id == nil then
      obj.id = addon:CreateID("objective["..obj.name.."]-%i")
    elseif obj.rule.objectives[obj.id] then
      -- Unusual situation, should never end up here
      addon:warn(obj.id.." is already being tracked")
      return
    end
    if obj.progress == nil then
      obj.progress = 0
    end
    if obj.metadata == nil then
      obj.metadata = {}
    end
    if obj.tempdata == nil then
      obj.tempdata = {}
    end

    -- Add predefined methods here
    obj.HasCondition = objective_HasCondition
    obj.GetMetadata = objective_GetMetadata
    obj.SetMetadata = objective_SetMetadata

    -- All objectives created for a rule are stored together
    -- so that they can be quickly evaluated together
    obj.rule.objectives[obj.id] = obj
  end

  quest.id = addon:CreateID("quest-%i")
  return quest
end

function addon.QuestEngine:DeactivateQuest(quest)
  for _, obj in pairs(quest.objectives) do
    obj.rule.objectives[obj.id] = nil
  end

  return quest
end
