local _, addon = ...
addon:traceFile("conditions/position.lua")
local compiler, tokens = addon.QuestScriptCompiler, addon.QuestScript.tokens

local defaultRadius = 0.5

compiler:AddScript(tokens.PARAM_POSX, tokens.METHOD_EVAL, function(obj, targetX)
  local radius = obj.conditions[tokens.PARAM_RADIUS] or defaultRadius
  local pos = addon:GetPlayerLocation()
  local diff = math.abs(pos.x - targetX)
  -- addon.Logger:Trace("Diff X:", diff, "Radius:", radius)
  return diff < radius
end)

compiler:AddScript(tokens.PARAM_POSY, tokens.METHOD_EVAL, function(obj, targetY)
  local radius = obj.conditions[tokens.PARAM_RADIUS] or defaultRadius
  local pos = addon:GetPlayerLocation()
  local diff = math.abs(pos.y - targetY)
  -- addon.Logger:Trace("Diff Y:", diff, "Radius:", radius)
  return diff < radius
end)

compiler:AddScript(tokens.PARAM_ZONE, tokens.METHOD_EVAL, function(obj, targetZone)
  return addon:CheckPlayerInZone(targetZone)
end)

compiler:AddScript(tokens.PARAM_SUBZONE, tokens.METHOD_EVAL, function(obj, targetSubzone)
  return addon:CheckPlayerInZone(targetSubzone)
end)