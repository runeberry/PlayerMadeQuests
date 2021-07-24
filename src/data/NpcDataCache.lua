local _, addon = ...
local time = addon.G.time

addon.NpcDataCache = addon:NewRepository("NpcData", "Name")
addon.NpcDataCache:SetSaveDataSource("NpcDataCache")
addon.NpcDataCache:EnableWrite(true)
addon.NpcDataCache:EnableDirectRead(true)
addon.NpcDataCache:EnableCompression(false)
addon.NpcDataCache:EnableGlobalSaveData(true)

function addon.NpcDataCache:GetNpcDataByName(unitName, dataField, includeTimestamp)
  local npcData = self:FindByID(unitName)

  if not dataField then
    if includeTimestamp then
      -- Return the whole cached object and timestamp
      return npcData, npcData["@"]
    else
      -- Return the whole cached object
      return npcData
    end

  elseif npcData then
    if includeTimestamp then
      -- Return the specified field value and the timestamp at which it was cached
      return npcData[dataField], npcData[dataField.."@"]
    else
      -- Return only the specified field value
      return npcData[dataField]
    end
  end
end

function addon.NpcDataCache:SetNpcDataByName(unitName, dataField, dataValue)
  if unitName == nil or dataField == nil or dataValue == nil then return end

  local npcData = self:FindByID(unitName) or {
    Name = unitName,
  }

  local timestamp = time()
  npcData["@"] = timestamp
  npcData[dataField] = dataValue
  npcData[dataField.."@"] = timestamp

  self:Save(npcData)
end