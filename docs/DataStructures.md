# Data Structures

Properties identified as `[Persistent]` will be written to the player's SavedVariables. All other properties must be programatically restored when the player's UI is reloaded.

Methods identified as `[Required]` must be defined on the object before it can be used by the QuestEngine. Failure to define these methods will cause an error to be thrown during quest evaluation. All other methods are considered optional and allow you to hook into the quest evaluation lifecycle if desired.

### Quest

```lua
quest = {
  --[[
    Unique id for this quest. Currently explicitly defined in DemoQuestDB,
    but will be replaced by a hash in the future
    [Persistent]
  --]]
  id = "string",

  Nice name of the quest to show in the quest log
  [Persistent]
  name = "string",

  --[[
    The recommended player level to complete this quest
    [Persistent]
  --]]
  level = 60,

  -- Array of all Objectives that are tracked for this quest
  objectives = { Objective }
}
```

### Rule

A Rule is a template for creating an Objective, and represents a type of in-game action that should trigger quest progress. A Rule is basically a vessel to listen for, filter, and transform Event API events, then pipe these events to the correct Objectives for processing.

For example: "kill, "talkto", and "emote" are three different Rules that can trigger Objective progress.

```lua
rule = {
  --[[
    Unique name of the Rule. This property is a required parameter of NewRule() and will set on this property on the returned object. This is also the name of the RuleEvent you will publish to in order to process Objectives backed by this Rule.
  --]]
  name = "string",

  --[[
    Array of all active Objectives backed by this Rule. This array is created when NewRule() is called and populated each time CreateObjective() is called.
  --]]
  objectives = { Objective }
}

--[[
  Optional lifecycle hook that will be run whenever CreateObjective() is run for this Rule. This is the last step before CreateObjective() returns.
--]]
function rule:OnCreateObjective(objective) end

--[[
  Optional lifecycle hook that will run just BEFORE any Conditions
  are checked. If you explicitly return false, then Conditions will
  be skipped and the Objective will NOT progress. If you return true
  or nothing at all, then Condition evaluation will follow.

  The varargs for this method will be the payload of the RuleEvent
  that triggered this Objective to be evaluated.
--]]
function rule:BeforeCheckConditions(objective, ...) end

--[[
  Optional lifecycle hook that will run AFTER all Conditions have been checked, but BEFORE the Objective is progressed. The second argument, "result", will be true if all Conditions were evaluated as true, false otherwise.

  The varargs for this method will be the payload of the RuleEvent
  that triggered this Objective to be evaluated.

  If you return false, then the Objective will NOT be progressed, regardless of the Condition result.
  If you return true or 1, then the Objective will be advanced by 1 (default behavior).
  If you return a value > 1, then the Objective will be advanced by that amount.
  If you return nil, void, or a non-number, then the default behavior will be observed.
--]]
function rule:AfterCheckConditions(objective, result, ...) end
```

### Condition

A Condition represents a circumstance that must be true when a Rule is triggered in order for progress to be made on an Objective.

For example: "While {x} is equipped", "While {x} is targeted", or "While in zone {x}" would all be Conditions, where "{x}" will be defined on the Objective when it is created.

```lua
condition = {
  --[[
    The primary name of this Condition, which is the first parameter
    passed to NewCondition(). All other names passed to
    NewCondition() will alias back to this name.
  --]]
  name = "string",

  --[[
    Declares whether or not multiple values are allowed for this Condition
    when declaring an Objective. For example, in the following script:
    `talkto t=Cow t=Rexxar t=Chepi`
    If allowMultiple == false, then only the last value will be observed.
      in CheckCondition, arg == "Chepi"
    If allowMultiple == true, then values will be preserved as a distinct set.
      in CheckCondition, arg ==
        { ["Cow"] == true, ["Rexxar"] == true, ["Chepi"] == true }
    By default, allowMultiple is false.
  --]]
  allowMultiple = false
}

--[[
  This method must be defined before a Condition can be processed by
  the QuestEngine. The second parameter, arg, represents the value of
  the parameter when this Condition was applied to the Objective, but its
  structure changes depending on whether or not AllowMultiple is true.

  This method should return true if the Condition is met, or false otherwise.
  Returning nil (or not returning at all) will evaluate as false.
  [Required]
--]]
function condition:CheckCondition(objective, arg) end
```

### Objective

An Objective is a specific instance of a Rule that is created when it is applied to a quest. Objectives have a Goal of 1 or more, which represents the number of times that the Rule must be performed in order to complete the Objective. Objectives are usually accompanied with one or more Conditions.

An Objective can be thought of as: Rule + Goal + Condition(s)

```lua
objective = {
  -- Reference to the Rule backing this Objective
  rule = Rule,

  --[[
    Unique ID for this Objective. Generated when the Objective
    is loaded into memory.
  --]]
  id = "string",

  --[[
    The name of the Rule backing this Objective
    [Persistent]
  --]]
  name = "string",

  --[[
    Player's current progress on this Objective
    [Persistent]
  --]]
  progress = 0,

  --[[
    When progress >= goal, then the Objective is fulfilled.
    Goal must be >= 0 when created.
    [Persistent]
  --]]
  goal = 1,

  --[[
    A table containing the names of the Conditions for this Objective
    along with the parameter values associated with each Condition.
    The structure of each value depends on whether or not allowMultiple
    is enabled.
    [Persistent]
  --]]
  conditions = {
    -- example of allowMultiple == true
    ["target"] = { ["Rexxar"] = true, ["Chepi"] = true },
    -- example of allowMultiple == false
    ["emote"] = "dance"
  }

  -- Any additional data that will be written to save.
  -- [Persistent]
  metadata = {},

  -- Any additional method that will not be written to save.
  tempdata = {}
}

--[[
  Returns true if the objective was created with the specified condition,
  false otherwise. Only works with the primary name of the Condition, not
  any of the aliases.
--]]
objective:HasCondition(name)

--[[
  Sets the specified value as metadata at the specified key. If `persistent`
  is specified and true, then the value will be stored in the save file.
  If non-serializable data is set as persistent, then an error will be
  triggered on save.
--]]
objective:SetMetadata(name, value, persistent)

--[[
  Returns the value specified at this key on `metadata` if it exists, otherwise
  the value specified on `tempdata`, otherwise nil.
--]]
objective:GetMetadata(name)
```