local _, addon = ...
addon:traceFile("rules/TargetMob.lua")

local rule = {
  name = "TargetMob",
  displayText = "Target %1 %p/%g",
  events = {
    PLAYER_TARGET_CHANGED = function(obj, ...)
      if UnitExists("target") then
        -- Advance objective if targeted unit name matches objective's unitName
        return obj.args[1] == GetUnitName("target", true)
      end
    end
  }
}

addon.rules:Define(rule)