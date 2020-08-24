local _, addon = ...
local time, strsplit = addon.G.time, addon.G.strsplit

local idCounter = 0
-- Returns a string ID based on an incrementing counter and the current time
function addon:CreateID(str)
  idCounter = idCounter + 1
  local id = time().."-"..idCounter
  if str then
    id = string.gsub(str, "%%i", id)
  end
  return id
end

-- Parses a GUID string into a table with named properties
-- Parsed based on this information: https://wow.gamepedia.com/GUID
function addon:ParseGUID(guid)
  local parsed = {
    GUID = guid
  }

  local parts = { strsplit("-", parsed.GUID) }
  local numParts = addon:tlen(parts)

  if numParts == 3 then
    -- unit is another player
    parsed.type = parts[1]
    parsed.serverID = parts[2]
    parsed.UID = parts[3]
  elseif numParts == 4 then
    -- unit is an item (does not contain any helpful identification)
    parsed.type = parts[1]
    parsed.serverID = parts[2]
    parsed.UID = parts[4]
  elseif numParts == 7 then
    -- unit is a creature, pet, object, or vehicle
    parsed.type = parts[1]
    parsed.serverID = parts[3]
    parsed.instanceID = parts[4]
    parsed.zoneUID = parts[5]
    parsed.ID = parts[6]
    parsed.spawnUID = parts[7]
  else
    error("Unrecognized GUID format: "..parsed.GUID)
  end

  return parsed
end