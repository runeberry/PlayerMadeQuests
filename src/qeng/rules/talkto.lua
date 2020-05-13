local _, addon = ...
addon:traceFile("rules/talkto.lua")
local UnitExists = addon.G.UnitExists

local rule = addon.QuestEngine:NewRule("talkto")

function rule:GetDisplayText(obj)
  return "Talk to "..obj:GetConditionDisplayText("target", "anyone")
end

-- Publish the TalkTo event anytime the player targets a friendly unit
-- that activates one of the registered events below
local function publishEvent()
  if UnitExists("target") then
    addon.RuleEvents:Publish(rule.name)
  end
end

addon:onload(function()
  addon.GameEvents:Subscribe("AUCTION_HOUSE_SHOW", publishEvent)
  addon.GameEvents:Subscribe("BANKFRAME_OPENED", publishEvent)
  addon.GameEvents:Subscribe("GOSSIP_SHOW", publishEvent)
  addon.GameEvents:Subscribe("MERCHANT_SHOW", publishEvent)
  addon.GameEvents:Subscribe("PET_STABLE_SHOW", publishEvent)
  addon.GameEvents:Subscribe("QUEST_DETAIL", publishEvent)
end)