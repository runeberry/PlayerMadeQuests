local _, addon = ...
local logger = addon.QuestEngine.ObjectiveLogger
local tokens = addon.QuestScriptTokens
local UnitExists, GetUnitName = addon.G.UnitExists, addon.G.GetUnitName
local CheckInteractDistance = addon.G.CheckInteractDistance

local talkEmoteMsg -- The expected emote message for the /talk emote

-- Publish the TalkTo event anytime the player targets a friendly unit
-- that activates one of the registered events below
local function publishEvent()
  if UnitExists("target") then
    addon.QuestEvents:Publish(tokens.OBJ_TALKTO)
  end
end

addon.GameEvents:Subscribe("AUCTION_HOUSE_SHOW", publishEvent)
addon.GameEvents:Subscribe("BANKFRAME_OPENED", publishEvent)
addon.GameEvents:Subscribe("GOSSIP_SHOW", publishEvent)
addon.GameEvents:Subscribe("MERCHANT_SHOW", publishEvent)
addon.GameEvents:Subscribe("PET_STABLE_SHOW", publishEvent)
addon.GameEvents:Subscribe("QUEST_DETAIL", publishEvent)
addon.GameEvents:Subscribe("QUEST_PROGRESS", publishEvent)

-- Allow the /talk emote to trigger this objective as well
addon.GameEvents:Subscribe("CHAT_MSG_TEXT_EMOTE", function(msg, playerName)
  if playerName == GetUnitName("player") and msg and UnitExists("target") then
    local talkEmoteMsgTargeted = talkEmoteMsg:gsub("%%t", GetUnitName("target"))
    if msg == talkEmoteMsgTargeted then
      if CheckInteractDistance("target", 5) then
        addon.QuestEvents:Publish(tokens.OBJ_TALKTO)
      else
        logger:Trace("Not close enough to /talk to target")
      end
    end
  end
end)

-- Store the /talk chat message on startup for quick comparison
addon:onload(function()
  local emote = addon.Emotes:FindByCommand("/talk")
  talkEmoteMsg = emote.targeted
end)