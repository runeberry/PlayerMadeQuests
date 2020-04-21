# Data Structures

## SavedVariables (per Character)

```lua
{
  QuestLog = { Quest } -- Array of
}
```

## Quest

```lua
{
  -- Unique id for this quest. Currently defined in data.
  id = "string",

  -- Nice name of the quest to show in the quest log
  name = "string",

  -- Author of this quest (format: "Name-Realm")
  author = "string",

  -- Array of all Objectives for this quest
  objectives = { Objective }
}
```

## Rule

```lua
{
  -- Unique name of the rule. property added when Define() is called
  name = "string",

  -- Optional method. Varargs come from: rules:OnAddObjective(name, goal, ...)
  onAddObjective = function(objective, ...) end

  events = {
    EVENT_NAME = function(objective, cl, ...) return true end
  }

  combatLogEvents = {
    EVENT_NAME = function(objective, cl, ...) return true end
  }

  -- Array of all active Objectives obeying this rule.
  -- This array is created when rules:Define is called
  -- and populated each time rules:AddObjective is called.
  objective = { Objective }
}


function rule:OnAddObjective(objective, ...) end
```

## Objective

```lua
{
  -- Reference to the Rule backing this objective
  rule = Rule,

  -- Player's current progress on this objective
  progress = 0,

  -- When progress >= goal, then the objective is fulfilled.
  -- Goal must be >= 0 when created.
  goal = 1,

  -- additional properties may be stored on an objective, depending on the Rule
}
```
