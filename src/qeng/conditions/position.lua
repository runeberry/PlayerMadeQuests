local _, addon = ...
local loader = addon.QuestScriptLoader
local tokens = addon.QuestScriptTokens

local defaultRadius = 0.5

loader:AddScript(tokens.PARAM_COORDS, tokens.METHOD_PARSE, function(targetCoords)
  assert(type(targetCoords) == "string", type(targetCoords).." is not a valid type for "..tokens.PARAM_COORDS)

  local x, y, radius = addon:ParseCoords(targetCoords)
  return { x = x, y = y, radius = radius }
end)

loader:AddScript(tokens.PARAM_COORDS, tokens.METHOD_EVAL, function(obj, targetCoords)
  local radius = targetCoords.radius or defaultRadius

  local pos = addon:GetPlayerLocation()
  local diffX = math.abs(pos.x - targetCoords.x)
  local diffY = math.abs(pos.y - targetCoords.y)

  addon.Logger:Trace("Distance from target coords: (%.2f, %.2f) targeting radius %.2f", diffX, diffY, radius)
  return diffX < radius and diffY < radius
end)

loader:AddScript(tokens.PARAM_ZONE, tokens.METHOD_EVAL, function(obj, targetZone)
  return addon:CheckPlayerInZone(targetZone)
end)

loader:AddScript(tokens.PARAM_SUBZONE, tokens.METHOD_EVAL, function(obj, targetSubzone)
  return addon:CheckPlayerInZone(targetSubzone)
end)