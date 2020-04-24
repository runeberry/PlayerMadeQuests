local _, addon = ...
addon:traceFile("rules/RulesCore.lua")

local rules = {
  definitions = {}
}
local oidCounter = 0

local function getObjectiveId()
  oidCounter = oidCounter + 1
  return oidCounter
end

local function wrapRuleHandler(rule, handler)
  -- Given an arbitrary list of game event args, handle them as follows
  return function(...)
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
        local ok, result = addon:catch(handler, obj, ...)
        local changed = false

        if not(ok) then
          -- Something messed up, don't advance objective
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
        end

        if changed then
          -- Sanity checks: progress must be >= 0, and progress must be an integer
          obj.progress = math.max(math.floor(obj.progress), 0)

          if rule.onUpdateObjective then
            rule.onUpdateObjective(obj)
          end

          addon.QuestEvents:Publish("ObjectiveUpdated", obj)

          if obj.progress >= obj.goal then
            -- Mark objective for removal from further checks
            table.insert(completed, i)
            if rule.onCompleteObjective then
              rule.onCompleteObjective(obj)
            end

            addon.QuestEvents:Publish("ObjectiveCompleted", obj)

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

-- Each rule must be Defined before objectives can be created from it
function rules:Define(rule)
  if rule == nil then
    addon:error("Cannot define quest rule - rule is nil")
    return
  end

  if rule.name == nil then
    addon:error("Cannot define quest rule - name is required")
    return
  end

  if self.definitions[rule.name] ~= nil then
    addon:warn("Skipping quest rule - name '" .. rule.name .. "' is already defined")
    return
  end

  -- Listen to the appropriate game events to satisfy these rules
  local numEvents = 0
  if rule.events ~= nil then
    for evt, handler in pairs(rule.events) do
      addon.GameEvents:Subscribe(evt, wrapRuleHandler(rule, handler))
      numEvents = numEvents + 1
    end
  end
  if rule.combatLogEvents ~= nil then
    for evt, handler in pairs(rule.combatLogEvents) do
      addon.CombatLogEvents:Subscribe(evt, wrapRuleHandler(rule, handler))
      numEvents = numEvents + 1
    end
  end

  if numEvents == 0 then
    addon:warn("Skipping quest rule - no game events were associated with rule '"..rule.name.."'")
    return
  end

  -- Objectives created for this rule will be attached to the rule
  rule.objectives = {}
  self.definitions[rule.name] = rule
  addon:trace("Registered quest rule: '" .. rule.name .. "'")
end

-- Add a new objective for a given rule
-- Additional parameters are passed to the OnCreate method of the rule
function rules:AddObjective(name, goal, ...)
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

  if rule.onAddObjective ~= nil then
    -- Optional hook for a rule to modify an objective on creation
    -- Can be used to store additional data with each objective for this rule
    rule.onAddObjective(objective, ...)
  end

  -- All objectives created for a rule are stored together
  -- so that they can be quickly evaluated together
  table.insert(rule.objectives, objective)

  -- Return the created objective so it can be attached to the quest as well
  return objective
end

function rules:LoadObjective(str)
  -- todo: Can't use unitName, need a more generic approach to rule args
  local ruleName, progress, goal, args = strsplit(",", str, 4)
  local obj
  if args == nil or args == "" then
    obj = rules:AddObjective(ruleName, tonumber(goal))
  else
    local argsTable = { strsplit(",", args) }
    obj = rules:AddObjective(ruleName, tonumber(goal), unpack(argsTable))
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

addon.rules = rules;