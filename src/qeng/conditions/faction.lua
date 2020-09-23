local _, addon = ...

local condition = addon.QuestEngine:NewCondition("faction")
condition:AllowType("string")

function condition:OnParse(args)
  return args:lower()
end

function condition:Evaluate(faction)
  return addon:GetPlayerFaction() == faction
end