local _, addon = ...

local condition = addon.QuestEngine:NewCondition("class")
condition:AllowType("string")
condition:AllowValues(addon.WOW_CLASS_NAMES)

function condition:OnParse(args)
  return args:lower()
end

function condition:Evaluate(class)
  return addon:GetPlayerClass():lower() == class
end