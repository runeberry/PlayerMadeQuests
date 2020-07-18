local _, addon = ...
local loader = addon.QuestScriptLoader
local tokens = addon.QuestScriptTokens

loader:AddScript(tokens.OBJ_EXPLORE, tokens.METHOD_POST_EVAL, function(obj, result, locData)
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
  addon.QuestEvents:Publish(tokens.OBJ_EXPLORE, addon:GetPlayerLocation())
end

local function refreshLocation()
  addon:GetPlayerLocation(true)
end

addon.AppEvents:Subscribe("PlayerLocationChanged", publish)

addon.AppEvents:Subscribe("QuestAdded", refreshLocation)
addon.AppEvents:Subscribe("QuestLogBuilt", refreshLocation)
addon.AppEvents:Subscribe("QuestTrackingStarted", refreshLocation)
addon.GameEvents:Subscribe("ZONE_CHANGED", refreshLocation)
addon.GameEvents:Subscribe("ZONE_CHANGED_INDOORS", refreshLocation)
addon.GameEvents:Subscribe("ZONE_CHANGED_NEW_AREA", refreshLocation)

addon.AppEvents:Subscribe("ObjectiveCompleted", function(obj)
  addon:StopPollingLocation(obj.id)
end)