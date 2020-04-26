local _, addon = ...
addon:traceFile("RulesCore.lua")

local rules = {
  definitions = {}
}
local oidCounter = 0

local function getObjectiveId()
  oidCounter = oidCounter + 1
  return oidCounter
end

local function wrapRuleHandler(rule)
  -- Given an arbitrary list of game event args, handle them as follows
  return function(...)
    -- Before this rule is run for the first time, validate that it was setup correctly
    if rule._validated == nil then
      if rule.CheckObjective == nil or type(rule.CheckObjective) ~= "function" then
        addon:error("Cannot run quest rule - must have a CheckObjective function")
        rule._validated = false
        return
      end
      rule._validated = true
    elseif rule._validated == false then
      return
    end

    -- Completed objectives will be tracked and removed from the list
    local completed = {}
    local anychanged = false

    -- For each objective that is backed by this rule
    for i, obj in pairs(rule.objectives) do
      if obj.progress >= obj.goal then
        -- The objective is already completed, nothing to do
        table.insert(completed, i)
      else
        -- Run the handler for this event for this rule, passing through the event's varargs
        local ok, result = addon:catch(rule.CheckObjective, rule, obj, ...)
        local changed = false

        if not(ok) then
          -- Something messed up, don't advance objective
          if result then
            addon:error("Error checking quest objective for rule", rule.name, "-", result)
          else
            addon:error("Error checking quest objective for rule", rule.name)
          end
        elseif result == nil or result == false then
          -- No result == false result == no objective progress
        elseif result == true then
          -- If the handler returns true, then objective progress is advanced by 1
          obj.progress = obj.progress + 1
          changed = true
        elseif type(result) == "number" then
          -- If it returns a number, then objective progress is advanced by that amount
          -- Note that this can be negative to "undo" objective progress
          obj.progress = obj.progress + result
          changed = true
        else
          addon:warn("Unexpected result from checking quest objective for rule", rule.name, "-", result)
        end

        if changed then
          -- Sanity checks: progress must be >= 0, and progress must be an integer
          obj.progress = math.max(math.floor(obj.progress), 0)

          -- if rule.onUpdateObjective then
          --   rule.onUpdateObjective(obj)
          -- end

          addon.AppEvents:Publish("ObjectiveUpdated", obj)

          if obj.progress >= obj.goal then
            -- Mark objective for removal from further checks
            table.insert(completed, i)
            -- if rule.onCompleteObjective then
            --   rule.onCompleteObjective(obj)
            -- end

            addon.AppEvents:Publish("ObjectiveCompleted", obj)

            addon.qlog:TryCompleteQuest(obj.quest.id)
          end

          anychanged = true
        end
      end
    end

    for _, i in pairs(completed) do
      -- Stop trying to update that objective on subsequent game events
      table.remove(rule.objectives, i)
    end

    if anychanged then
      addon.qlog:Save()
    end
  end
end

function rules:CreateRule(name)
  if name == nil or name == "" then
    error("Cannot create rule - name is required")
  end

  if self.definitions[name] ~= nil then
    addon:warn("Skipping quest rule - '" .. name .. "' is already defined")
    return
  end

  local rule = {
    name = name,
    displayText = name.." %p/%g",
    objectives = {}
  }

  addon.RuleEvents:Subscribe(name, wrapRuleHandler(rule))

  self.definitions[name] = rule
  addon:trace("Registered quest rule: '" .. rule.name .. "'")
  return rule
end

-- Add a new objective for a given rule
-- Additional parameters are passed to the OnCreate method of the rule
function rules:CreateObjective(name, goal, ...)
  if name == nil then
    error("Unable to create quest objective - provided name is nil")
  end

  local rule = self.definitions[name]
  if rule == nil then
    error("Unable to create quest objective - no rule exists with name '"..name.."'")
  end

  if type(goal) ~= "number" or goal <= 0 then
    error("Unable to create quest objective - goal must be > 0")
  end

  local objective = {
    id = getObjectiveId(),
    rule = rule,
    progress = 0,
    goal = goal,
    args = { ... }
  }

  -- if rule.onAddObjective ~= nil then
  --   -- Optional hook for a rule to modify an objective on creation
  --   -- Can be used to store additional data with each objective for this rule
  --   rule.onAddObjective(objective, ...)
  -- end

  -- All objectives created for a rule are stored together
  -- so that they can be quickly evaluated together
  table.insert(rule.objectives, objective)

  -- Return the created objective so it can be attached to the quest as well
  return objective
end

function rules:LoadObjective(str)
  local ruleName, progress, goal, args = strsplit(",", str, 4)
  local obj
  if args == nil or args == "" then
    obj = rules:CreateObjective(ruleName, tonumber(goal))
  else
    local argsTable = { strsplit(",", args) }
    obj = rules:CreateObjective(ruleName, tonumber(goal), unpack(argsTable))
  end
  -- todo: shouldn't technically add the objective if it's already completed
  obj.progress = tonumber(progress)
  return obj
end

function rules:SerializeObjective(obj)
  local serialized = obj.rule.name..","..tostring(obj.progress)..","..tostring(obj.goal)

  for _, v in pairs(obj.args) do
    serialized = serialized..","..v
  end

  return serialized
end

addon.Rules = rules;