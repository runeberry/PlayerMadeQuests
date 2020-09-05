local _, addon = ...
local UnitClass = addon.G.UnitClass

local condition = addon.QuestEngine:NewCondition("class")
condition:AllowType("string")

function condition:OnParse(args)
  return args:lower()
end

function condition:Evaluate(class)
  return UnitClass("player"):lower() == class
end