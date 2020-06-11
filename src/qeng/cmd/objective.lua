local _, addon = ...
addon:traceFile("cmd/objective.lua")
local compiler, tokens = addon.QuestScriptCompiler, addon.QuestScript.tokens
local unpack = addon.G.unpack

compiler:AddScript(tokens.CMD_OBJ, tokens.METHOD_PARSE, function(quest, args)
  local objName = args:GetValue(tokens.PARAM_NAME)
  if not objName then
    error("Objective name is required")
  end

  objName = objName:lower()
  local objInfo = compiler:GetObjectiveInfo(objName)
  if not objInfo then
    error("Unknown objective: "..objName)
  end

  local objective = {
    --id = addon:CreateID("objective:"..rule.."-%i"),
    --rule = rules[p1], -- The objective contains a reference to its backing rule
    name = objName, -- objective name == rule name
    displayText = objName.." %p/%g",
    --progress = 0, -- All objectives start at 0 progress
    goal = 1, -- Objective goal will be 1 unless otherwise defined
    conditions = {}, -- The conditions under which this objective must be completed
    --metadata = {}, -- Additional data for this objective that can be written to save
    --tempdata = {} -- Additional data that will not be written to save
  }

  -- Only treat param #2 as the goal if it's a number.
  -- Otherwise treat it as param #1 for the upcoming objective.
  local goal = args:GetValue(tokens.PARAM_GOAL)
  if goal and type(goal) == "number" and goal > 0 then
    objective.goal = goal
  else
    goal = nil
  end

  local displayText = args:GetValue(tokens.PARAM_TEXT)
  if displayText then
    objective.displayText = displayText
  end

  -- Before processing objective parameters, a little hackiness has to happen
  -- If the objective name or goal were specified as ordered parameters,
  -- they need to be removed here. By doing this, the following ordered parameters
  -- for objective parameters can be handled consistently. For example, in:
  --     objective emote 2 dance "Stormwind Guard"
  --     |_0       |1    |2|3    |4         <-- literal order
  --               |_0     |1    |2         <-- corrected order for objective parameters
  -- but also...
  --     objective g=2 name=emote dance "Stormwind Guard"
  --     |_0       |g  |n         |1    |2  <-- literal order
  --                   |_0        |1    |2  <-- corrected order for objective parameters

  if goal and args.ordered[2] and args.ordered[2].value == goal then
    table.remove(args.ordered, 2)
  end
  if args.ordered[1] and args.ordered[1].value == objName then
    table.remove(args.ordered, 1)
  end

  args._parentName = objName
  args._parent = objInfo

  for _, param in ipairs(objInfo.params) do
    local val = args:GetValues(param.name)
    if val then
      objective.conditions[param.name] = addon:DistinctSet(val)
    end
  end

  if not quest.objectives then
    quest.objectives = {}
  end

  table.insert(quest.objectives, objective)
end)