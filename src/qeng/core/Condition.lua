local _, addon = ...

local methods = {
  ["BeforeEvaluate"] = nil,
  ["Evaluate"] = nil,
  ["AfterEvaluate"] = nil,
}

--- Creates a new Condition that is recognized by the QuestEngine.
--- A Condition is a Parameter that that can be evaluated as true or false during gameplay.
function addon.QuestEngine:NewCondition(name)
  local condition = self:NewParameter(name)

  for fname, fn in pairs(methods) do
    condition[fname] = fn
  end

  addon.QuestEngine:AddDefinition("conditions", name, condition)
  return condition
end