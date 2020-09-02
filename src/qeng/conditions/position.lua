local _, addon = ...

local defaultRadius = 0.5

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_COORDS)
condition:AllowType("string")

function condition:OnParse(arg)
  local x, y, radius = addon:ParseCoords(arg)
  return { x = x, y = y, radius = radius }
end

function condition:Evaluate(targetCoords)
  local radius = targetCoords.radius or defaultRadius

  local pos = addon:GetPlayerLocation()
  local diffX = math.abs(pos.x - targetCoords.x)
  local diffY = math.abs(pos.y - targetCoords.y)

  self.logger:Trace("Target coords diff: (%.2f, %.2f) @ radius %.2f", diffX, diffY, radius)
  local result = diffX < radius and diffY < radius
  if result then
    self.logger:Pass("Player within coords")
  else
    self.logger:Fail("Player not within coords")
  end
  return result
end

local zoneCondition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_ZONE)
zoneCondition:AllowType("string")

function zoneCondition:Evaluate(targetZone)
  local result = addon:CheckPlayerInZone(targetZone)
  if result then
    self.logger:Pass("Player in zone: %s", targetZone)
  else
    self.logger:Fail("Player not in zone: %s", targetZone)
  end
  return result
end

local subzoneCondition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_SUBZONE)
subzoneCondition:AllowType("string")

function subzoneCondition:Evaluate(targetSubzone)
  local result = addon:CheckPlayerInZone(targetSubzone)
  if result then
    self.logger:Pass("Player in subzone: %s", targetSubzone)
  else
    self.logger:Fail("Player not in subzone: %s", targetSubzone)
  end
  return result
end
