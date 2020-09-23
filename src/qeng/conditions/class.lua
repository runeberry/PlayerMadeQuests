local _, addon = ...

local condition = addon.QuestEngine:NewCondition("class")
condition:AllowType("string")

function condition:OnParse(args)
  return args:lower()
end

function condition:Evaluate(class)
  return addon:GetPlayerClass() == class
end