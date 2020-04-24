local _, addon = ...
addon:traceFile("rules/KillMob.lua")

local rule = {
  name = "KillMob",
  displayText = "Kill %1 %p/%g",
  combatLogEvents = {
    PARTY_KILL = function(obj, cl)
      -- Advance objective if killed unit name matches objective's unitName
      return cl.destName == obj.args[1]
    end
  }
}

addon.rules:Define(rule)