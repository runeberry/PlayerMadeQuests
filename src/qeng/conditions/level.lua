local _, addon = ...

local condition = addon.QuestEngine:NewCondition("level")
condition:AllowType("number")

function condition:Evaluate(level)
  return addon:GetPlayerLevel() >= level
end