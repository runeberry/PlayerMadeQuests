local _, addon = ...
addon:traceFile("rules/KillMob.lua")

local rule = {
  name = "KillMob",
  onAddObjective = function(obj, ...)
    local unitName = ...
    obj.unitName = unitName

    if obj.unitName == nil or obj.unitName == "" then
      addon:warn("KillMob objective was created with no unitName to track")
    end
  end,
  onUpdateObjective = function(obj)
    addon:info("You have killed", obj.progress, "of", obj.goal, addon:pluralize(obj.goal, obj.unitName))
  end,
  onCompleteObjective = function(obj)
    addon:info("You have killed enough", addon:pluralize(obj.goal, obj.unitName), "!")
  end,
  combatLogEvents = {
    PARTY_KILL = function(obj, cl)
      -- Advance objective if killed unit name matches objective's unitName
      return cl.destName == obj.unitName
    end
  }
}

addon.rules:Define(rule)