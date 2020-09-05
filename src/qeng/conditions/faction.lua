local _, addon = ...
local UnitFactionGroup = addon.G.UnitFactionGroup

local condition = addon.QuestEngine:NewCondition("faction")
condition:AllowType("string")

function condition:OnParse(args)
  return args:lower()
end

function condition:Evaluate(faction)
  return UnitFactionGroup("player"):lower() == faction
end