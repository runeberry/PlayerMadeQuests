local _, addon = ...
local tokens = addon.QuestScriptTokens

local objective = addon.QuestEngine:NewObjective("explore")

objective:AddShorthandForm(tokens.PARAM_ZONE, tokens.PARAM_COORDS)

objective:AddParameter(tokens.PARAM_TEXT, {
  defaultValue = {
    log = "Go to %xysz",
    progress = "%xysz explored: %p/%g",
    quest = "Explore %xyz[%a: while having %a][%i: while having %i][%e: while wearing %e]",
    full = "Go to %xyrz[%a: while having %a][%i: while having %i][%e: while wearing %e]"
  },
})

objective:AddCondition(tokens.PARAM_AURA)
objective:AddCondition(tokens.PARAM_EQUIP)
objective:AddCondition(tokens.PARAM_ITEM)
objective:AddCondition(tokens.PARAM_ZONE)
objective:AddCondition(tokens.PARAM_SUBZONE)
objective:AddCondition(tokens.PARAM_COORDS)

objective:EvaluateOnQuestStart(true)
objective:AddAppEvent("PlayerLocationChanged")
objective:AddGameEvent("ZONE_CHANGED")
objective:AddGameEvent("ZONE_CHANGED_INDOORS")
objective:AddGameEvent("ZONE_CHANGED_NEW_AREA")

function objective:AfterEvaluate(result, obj)
  if obj.conditions[tokens.PARAM_COORDS] then
    self.logger:Trace("Objective has a '%s' parameter, checking to poll location...", tokens.PARAM_COORDS)
    -- If the objective specifies an X or Y position, then begin polling for X/Y changes
    -- on an interval whenever a player enters the correct zone(s)
    local z, sz = obj.conditions[tokens.PARAM_ZONE], obj.conditions[tokens.PARAM_SUBZONE]
    self.logger:Trace("zone: %s, subzone: %s", tostring(z), tostring(sz))
    local inZone = (not z) or addon:CheckPlayerInZone(z)
    local inSubZone = (not sz) or addon:CheckPlayerInZone(sz)

    if inZone and inSubZone then
      self.logger:Trace("Player is in zone, starting location polling")
      addon:StartPollingLocation(obj.id)
    else
      self.logger:Trace("Player is not in zone, stopping location polling")
      addon:StopPollingLocation(obj.id)
    end
  end
end

-- This doesn't necessarily have to go in this file, but I'll leave it here for now
addon.AppEvents:Subscribe("ObjectiveCompleted", function(obj)
  addon:StopPollingLocation(obj.id)
end)