local _, addon = ...

local condition = addon.QuestEngine:NewCondition("faction")
condition:AllowType("string")
condition:AllowValues({ "Alliance", "Horde" })

function condition:OnParse(args)
  return args:lower()
end

function condition:Evaluate(faction)
  return addon:GetPlayerFaction():lower() == faction
end