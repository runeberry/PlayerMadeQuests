local _, addon = ...
addon:traceFile("QuestEngine.lua")

addon.QuestEngine = {}

local rules = {}
local oidCounter = 0
local ruleNamePattern = "^%w+$"

local function getObjectiveId()
  oidCounter = oidCounter + 1
  return oidCounter
end

local function validateRuleName(name)
  if name == nil  then
    error("Invalid rule - name must not be nil")
  end

  if type(name) ~= "string" or not(name:match(ruleNamePattern)) then
    error("Invalid rule - name must match pattern: "..ruleNamePattern)
  end

  return name:lower()
end

local function dequote(str)
  if str:match("\"[%w%s]+\"") then
    str = str:gsub("\"", "")
  elseif str:match("'[%w%s]+'") then
    str = str:gsub("'", "")
  end
  return str
end

local function setNamedParam(tab, key, val)
  if tab[key] then
    table.insert(tab[key], val)
  else
    tab[key] = { val }
  end
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

function addon.QuestEngine:CreateRule(name)
  name = validateRuleName(name)

  local rule = {
    name = name,
    displayText = name.." %p/%g",
    objectives = {}
  }

  addon.RuleEvents:Subscribe(name, wrapRuleHandler(rule))

  rules[name] = rule
  addon:trace("Registered quest rule: '" .. rule.name .. "'")
  return rule
end

-- Add a new objective for a given rule
-- Additional parameters are passed to the OnCreate method of the rule
function addon.QuestEngine:CreateObjective(name, goal, ...)
  name = validateRuleName(name)

  local rule = rules[name]
  if rule == nil then
    error("Unable to create quest objective - no rule exists with name '"..name.."'")
  end

  if type(goal) ~= "number" or goal <= 0 then
    error("Unable to create quest objective - goal must be > 0")
  end

  local objective = {
    id = getObjectiveId(),
    rule = rule,
    name = name, -- objective name == rule name
    progress = 0,
    goal = goal,
    args = { ... }
  }

  -- All objectives created for a rule are stored together
  -- so that they can be quickly evaluated together
  table.insert(rule.objectives, objective)

  -- Return the created objective so it can be attached to the quest as well
  return objective
end

function addon.QuestEngine:ParseObjective(str)
  if str == nil or str == "" then
    error("Unable to parse objective - string is nil or empty")
  end

  local obj = {}

  -- Remove all extra whitespace
  str = addon:strtrimall(str)

  -- The first three parameters (at most) may have special handling
  local p1, p2, p3 = strsplit(str, " ")

  -- The first parameter must be a valid rule
  obj.rule = p1
  if rules[p1] == nil then
    error("Unable to parse objective - no rule exists with name: "..p1)
  end

  -- The second parameter may be either the goal or displayText
  local check3 = false
  local goal = tonumber(p2)
  if goal then
    obj.goal = goal
    check3 = true -- Only check param #3 if param #2 was definitely the goal
  else
    local dequoted = dequote(p2)
    if dequoted ~= p2 then
      -- If the string was enquoted, then it is the displayText
      obj.displayText = dequoted
    end
  end

  if check3 then
    local dequoted = dequote(p3)
    if dequoted ~= p3 then
      -- If the string was enquoted, then it is the displayText
      obj.displayText = dequoted
    end
  end

  local namedParams = {}
  -- Only recognize the remaining parameters in this format: a=b, a='c', or a="d"
  for word in str:gmatch("%w-=[^\"']%S+") do -- Unquoted format
    local k, v = strsplit(word, "=")
    setNamedParam(namedParams, k, v)
  end
  for word in str:gmatch("%w-='.-'") do -- Single-quoted format
    local k, v = strsplit(word, "=")
    setNamedParam(namedParams, k, dequote(v))
  end
  for word in str:gmatch('%w-=".-"') do -- Double-quoted format
    local k, v = strsplit(word, "=")
    setNamedParam(namedParams, k, dequote(v))
  end

  -- todo: objectives are parsed, where to go from here?
end