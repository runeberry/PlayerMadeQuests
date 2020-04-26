local _, addon = ...
addon:traceFile("TalkToNPC.lua")

local rule = addon.QuestEngine:CreateRule("TalkToNPC")
rule.displayText = "Talk to %1 %p/%g"

function rule:CheckObjective(obj, unitName)
  return obj.args[1] == unitName
end

-- Since the same information is used on several different game events, share this function
local function publishEvent()
  if UnitExists("target") then
    addon.RuleEvents:Publish(rule.name, GetUnitName("target", true))
  end
end

addon.GameEvents:Subscribe("AUCTION_HOUSE_SHOW", publishEvent)
addon.GameEvents:Subscribe("GOSSIP_SHOW", publishEvent)
addon.GameEvents:Subscribe("MERCHANT_SHOW", publishEvent)
addon.GameEvents:Subscribe("QUEST_DETAIL", publishEvent)