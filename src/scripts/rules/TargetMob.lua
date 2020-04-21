local _, addon = ...
addon:traceFile("rules/TargetMob.lua")

local rule = {
  name = "TargetMob",
  onAddObjective = function(obj, ...)
    local unitName = ...
    obj.unitName = unitName

    if obj.unitName == nil or obj.unitName == "" then
      addon:warn("TargetMob objective was created with no unitName to track")
    end
  end,
  onUpdateObjective = function(obj)
    addon:info("You have targeted", obj.progress, "of", obj.goal, addon:pluralize(obj.goal, obj.unitName))
  end,
  onCompleteObjective = function(obj)
    addon:info("You have targeted enough", addon:pluralize(obj.goal, obj.unitName), "!")
  end,
  events = {
    PLAYER_TARGET_CHANGED = function(obj, ...)
      if UnitExists("target") then
        -- Advance objective if targeted unit name matches objective's unitName
        return obj.unitName == GetUnitName("target", true)
      end
    end
  }
}

addon.rules:Define(rule)