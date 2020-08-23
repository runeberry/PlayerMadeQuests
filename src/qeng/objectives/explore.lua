local _, addon = ...
local logger = addon.QuestEngine.ObjectiveLogger
local loader = addon.QuestScriptLoader
local tokens = addon.QuestScriptTokens

loader:AddScript(tokens.OBJ_EXPLORE, tokens.METHOD_POST_EVAL, function(obj, result, locData)
  if obj.conditions[tokens.PARAM_COORDS] then
    logger:Trace("    Objective has a '%s' parameter, checking to poll location...", tokens.PARAM_COORDS)
    -- If the objective specifies an X or Y position, then begin polling for X/Y changes
    -- on an interval whenever a player enters the correct zone(s)
    local z, sz = obj.conditions[tokens.PARAM_ZONE], obj.conditions[tokens.PARAM_SUBZONE]
    logger:Trace("    zone: %s, subzone: %s", (z or "nil"), (sz or "nil"))
    local inZone = (not z) or addon:CheckPlayerInZone(z)
    local inSubZone = (not sz) or addon:CheckPlayerInZone(sz)

    if inZone and inSubZone then
      logger:Trace("    Player is in zone, starting location polling")
      addon:StartPollingLocation(obj.id)
    else
      logger:Trace("    Player is not in zone, stopping location polling")
      addon:StopPollingLocation(obj.id)
    end
  end
end)

local function publish()
  addon.QuestEvents:Publish(tokens.OBJ_EXPLORE, addon:GetPlayerLocation())
end

addon.AppEvents:Subscribe("QuestAdded", publish)
addon.AppEvents:Subscribe("QuestTrackingStarted", publish)
addon.GameEvents:Subscribe("ZONE_CHANGED", publish)
addon.GameEvents:Subscribe("ZONE_CHANGED_INDOORS", publish)
addon.GameEvents:Subscribe("ZONE_CHANGED_NEW_AREA", publish)

addon.AppEvents:Subscribe("PlayerLocationChanged", function(loc)
  addon.QuestEvents:Publish(tokens.OBJ_EXPLORE, loc)
end)

addon.AppEvents:Subscribe("ObjectiveCompleted", function(obj)
  addon:StopPollingLocation(obj.id)
end)