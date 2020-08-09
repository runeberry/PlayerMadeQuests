local _, addon = ...
local logger = addon.QuestEngine.ObjectiveLogger
local tokens = addon.QuestScriptTokens

local function publish()
  addon.QuestEvents:Publish(tokens.OBJ_AURA)
end

addon:onload(function()
  addon.GameEvents:Subscribe("UNIT_AURA", function(target)
    if target == "player" then
      publish()
    end
  end)
  addon.AppEvents:Subscribe("QuestTrackingStarted", publish)
  addon.AppEvents:Subscribe("QuestAdded", publish)
end)