local _, addon = ...
local logger = addon.QuestEngineLogger
local tokens = addon.QuestScriptTokens

addon:OnQuestEngineReady(function()
  local function publish()
    addon.QuestEvents:Publish(tokens.OBJ_EQUIP)
  end

  addon.AppEvents:Subscribe("PlayerInventoryChanged", publish)
  addon.AppEvents:Subscribe("QuestTrackingStarted", publish)
  addon.AppEvents:Subscribe("QuestAdded", publish)
end)