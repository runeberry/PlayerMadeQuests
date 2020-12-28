local _, addon = ...
local asserttype = addon.asserttype

--- Caches in-game items by name so that you can look up their ids
addon.GameItemCache = addon:NewRepository("GameItem", "name")
addon.GameItemCache:SetSaveDataSource("GameItemCache")
addon.GameItemCache:EnableWrite(true)
addon.GameItemCache:EnableDirectRead(true)
addon.GameItemCache:EnableCompression(false)
addon.GameItemCache:EnableGlobalSaveData(true)

function addon.GameItemCache:FindItemID(itemName)
  asserttype(itemName, "string", "itemName", "GetItemID")

  local entry = self:FindByID(itemName:lower())
  if not entry then return end

  return entry.id
end

function addon.GameItemCache:SaveItemID(itemName, itemId)
  asserttype(itemName, "string", "itemName", "SaveItemID")
  asserttype(itemId, "number", "itemId", "SaveItemID")

  -- Only update the cache if something is new or changed
  itemName = itemName:lower()
  local entry = self:FindByID(itemName)
  if not entry or entry.id ~= itemId then
    self:Save({ name = itemName, id = itemId })
  end
end

addon.AppEvents:Subscribe("ItemInfoAvailable", function(item)
  addon.GameItemCache:SaveItemID(item.name, item.id)
end)