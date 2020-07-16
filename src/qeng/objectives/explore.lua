local _, addon = ...
addon:traceFile("objectives/explore.lua")
local compiler, tokens = addon.QuestScriptCompiler, addon.QuestScript.tokens

compiler:AddScript(tokens.OBJ_EXPLORE, tokens.METHOD_POST_EVAL, function(obj, result, locData)
  if obj.conditions[tokens.PARAM_POSX] or obj.conditions[tokens.PARAM_POSY] then
    -- If the objective specifies an X or Y position, then begin polling for X/Y changes
    -- on an interval whenever a player enters the correct zone(s)
    local z, sz = obj.conditions[tokens.PARAM_ZONE], obj.conditions[tokens.PARAM_SUBZONE]
    local inZone = (not z) or addon:CheckPlayerInZone(z)
    local inSubZone = (not sz) or addon:CheckPlayerInZone(sz)

    if inZone and inSubZone then
      addon:StartPollingLocation(obj.id)
    else
      addon:StopPollingLocation(obj.id)
    end
  end
end)

local function publish()
  -- Calling GPL(true) here will ensure the data is refreshed for all conditions
  addon.QuestEvents:Publish(tokens.OBJ_EXPLORE, addon:GetPlayerLocation(true))
end

addon.AppEvents:Subscribe("PlayerLocationChanged", publish)
addon.AppEvents:Subscribe("QuestAdded", publish)
addon.AppEvents:Subscribe("QuestLogBuilt", publish)
addon.AppEvents:Subscribe("QuestTrackingStarted", publish)
addon.GameEvents:Subscribe("ZONE_CHANGED", publish)
addon.GameEvents:Subscribe("ZONE_CHANGED_INDOORS", publish)
addon.GameEvents:Subscribe("ZONE_CHANGED_NEW_AREA", publish)

addon.AppEvents:Subscribe("ObjectiveCompleted", function(obj)
  addon:StopPollingLocation(obj.id)
end)