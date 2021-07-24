local _, addon = ...
local asserttype = addon.asserttype

local GetClassInfo = addon.G.GetClassInfo
local GetRaceInfo = addon.G.GetRaceInfo

local factionLocalCache = {}
local sexLocalCache = {
  [1] = "Unknown",
  [2] = "Male",
  [3] = "Female",
}

function addon:GetClassNameById(classId)
  asserttype(classId, "number", "classId", "GetClassNameById", 2)
  local info = GetClassInfo(classId)
  return info and info.className
end

function addon:GetFactionNameById(factionId)
  if not factionId then return end
  return factionLocalCache[factionId] or factionId
end

function addon:SetFactionNameById(factionId, factionName)
  if not factionName then return end
  factionLocalCache[factionId] = factionName
end

function addon:GetRaceNameById(raceId)
  asserttype(raceId, "number", "raceId", "GetRaceNameById", 2)
  local info = GetRaceInfo(raceId)
  return info and info.raceName
end

function addon:GetSexNameById(sexId)
  asserttype(sexId, "number", "sexId", "GetSexNameById", 2)
  if not sexId then return end
  return sexLocalCache[sexId]
end