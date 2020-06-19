local _, addon = ...
addon:traceFile("conditions/position.lua")
local compiler, tokens = addon.QuestScriptCompiler, addon.QuestScript.tokens

compiler:AddScript(tokens.PARAM_POSX, tokens.METHOD_CHECK_COND, function(obj, targetX)
  local radius = obj:GetMetadata("PlayerLocationRadius")
  local pos = obj:GetMetadata("PlayerLocationData")
  local diff = math.abs(pos.x - targetX)
  -- addon.Logger:Trace("Diff X:", diff, "Radius:", radius)
  return diff < radius
end)

compiler:AddScript(tokens.PARAM_POSY, tokens.METHOD_CHECK_COND, function(obj, targetY)
  local radius = obj:GetMetadata("PlayerLocationRadius")
  local pos = obj:GetMetadata("PlayerLocationData")
  local diff = math.abs(pos.y - targetY)
  -- addon.Logger:Trace("Diff Y:", diff, "Radius:", radius)
  return diff < radius
end)

compiler:AddScript(tokens.PARAM_ZONE, tokens.METHOD_CHECK_COND, function(obj, targetZone)
  local pos = obj:GetMetadata("PlayerLocationData")
  local match = pos.zone == targetZone or pos.realZone == targetZone
  obj:SetMetadata("PlayerIsInZone", match)
  return match
end)

compiler:AddScript(tokens.PARAM_SUBZONE, tokens.METHOD_CHECK_COND, function(obj, targetSubzone)
  local pos = obj:GetMetadata("PlayerLocationData")
  local match = pos.subZone == targetSubzone or pos.minimapZone == targetSubzone
  obj:SetMetadata("PlayerIsInSubZone", match)
  return match
end)