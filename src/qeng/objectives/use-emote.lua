local _, addon = ...
local logger = addon.QuestEngine.ObjectiveLogger
local tokens = addon.QuestScriptTokens
local GetUnitName = addon.G.GetUnitName

addon:OnQuestEngineReady(function()
  addon.GameEvents:Subscribe("CHAT_MSG_TEXT_EMOTE", function(msg, playerName)
    if playerName == GetUnitName("player") and msg then
      -- Only handle emotes that the player performs
      addon.LastEmoteMessage = msg
      addon.QuestEvents:Publish(tokens.OBJ_EMOTE)
    end
  end)
end)