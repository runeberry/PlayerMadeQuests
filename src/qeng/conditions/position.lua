local _, addon = ...
local logger = addon.QuestEngine.ObjectiveLogger
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

  logger:Trace("        Target coords diff: (%.2f, %.2f) @ radius %.2f", diffX, diffY, radius)
  local result = diffX < radius and diffY < radius
  if result then
    logger:Debug(logger.pass.."Player within coords")
  else
    logger:Debug(logger.fail.."Player not within coords")
  end
  return result
end)

loader:AddScript(tokens.PARAM_ZONE, tokens.METHOD_EVAL, function(obj, targetZone)
  local result = addon:CheckPlayerInZone(targetZone)
  if result then
    logger:Debug(logger.pass.."Player in zone: %s", targetZone)
  else
    logger:Debug(logger.fail.."Player not in zone: %s", targetZone)
  end
  return result
end)

loader:AddScript(tokens.PARAM_SUBZONE, tokens.METHOD_EVAL, function(obj, targetSubzone)
  local result = addon:CheckPlayerInZone(targetSubzone)
  if result then
    logger:Debug(logger.pass.."Player in subzone: %s", targetSubzone)
  else
    logger:Debug(logger.fail.."Player not in subzone: %s", targetSubzone)
  end
  return result
end)