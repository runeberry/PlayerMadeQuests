local _, addon = ...
local UnitLevel = addon.G.UnitLevel

local condition = addon.QuestEngine:NewCondition("level")
condition:AllowType("number")

function condition:Evaluate(level)
  return UnitLevel("player") >= level
end