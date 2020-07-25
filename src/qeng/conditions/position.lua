local _, addon = ...
local loader = addon.QuestScriptLoader
local tokens = addon.QuestScriptTokens

local defaultRadius = 0.5
local coordCache = {}

loader:AddScript(tokens.PARAM_COORDS, tokens.METHOD_EVAL, function(obj, strTargetCoords)
  -- Parse coords string into a table of numbers, then cache the result
  -- todo: (#71) should be able to apply METHOD_PARSE to a condition to do this when the quest is compiled
  local targetCoords = coordCache[obj.id]
  if not targetCoords then
    local x, y, rad = addon:ParseCoords(strTargetCoords)
    targetCoords = { x = x, y = y, rad = rad }
    if not targetCoords.rad then
      targetCoords.rad = defaultRadius
    end
    coordCache[obj.id] = targetCoords
  end

  local pos = addon:GetPlayerLocation()
  local diffX = math.abs(pos.x - targetCoords.x)
  local diffY = math.abs(pos.y - targetCoords.y)
  -- addon.Logger:Trace("Distance from target coords:", addon:PrettyCoords(diffX, diffY, targetCoords.rad))
  return diffX < targetCoords.rad and diffY < targetCoords.rad
end)

loader:AddScript(tokens.PARAM_ZONE, tokens.METHOD_EVAL, function(obj, targetZone)
  return addon:CheckPlayerInZone(targetZone)
end)

loader:AddScript(tokens.PARAM_SUBZONE, tokens.METHOD_EVAL, function(obj, targetSubzone)
  return addon:CheckPlayerInZone(targetSubzone)
end)