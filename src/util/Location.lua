local _, addon = ...

local GetBestMapForUnit = addon.G.GetBestMapForUnit
local GetPlayerMapPosition = addon.G.GetPlayerMapPosition
local GetRealZoneText = addon.G.GetRealZoneText
local GetSubZoneText = addon.G.GetSubZoneText
local GetMinimapZoneText = addon.G.GetMinimapZoneText
local GetZoneText = addon.G.GetZoneText

local playerLocation

function addon:GetPlayerLocation(refresh)
  if not playerLocation or refresh then
    local map = GetBestMapForUnit("player")
    local x, y = 0, 0
    if map then
      local position = GetPlayerMapPosition(map, "player")
      x, y = position:GetXY()
    end

    playerLocation = {
      zone = GetZoneText(),
      realZone = GetRealZoneText(),
      subZone = GetSubZoneText(),
      minimapZone = GetMinimapZoneText(),
      x = x * 100,
      y = y * 100
    }
  end

  return playerLocation
end

function addon:CheckPlayerInZone(zone, refresh)
  local ld = addon:GetPlayerLocation(refresh)
  return ld.zone == zone or ld.realZone == zone or ld.subZone == zone or ld.minimapZone == zone
end
