local _, addon = ...
local logger = addon.Logger:NewLogger("Items")

local GetItemInfo = addon.G.GetItemInfo
local GetContainerItemInfo = addon.G.GetContainerItemInfo

-- Keeps track of when an inventory change is due to looting a mob
local didJustLoot = false

--- Represents the player's inventory in the order that it appears in the player's bags
local playerInventory = {
  loaded = false,
  -- Items are grouped per bag slot, as ordered in the player's inventory.
  -- Empty slots are not accounted for.
  bySlot = {
    -- Hash will change if the order of any items changes
    hash = 0,
    list = {},
  },
  -- Items are grouped by name and associated quantity
  byName = {
    -- use byId's hash
    list = {},
  },
  -- Items are grouped by id and associated quantity
  byId = {
    -- Hash will change only if an item is added or removed from the inventory
    hash = 0,
    list = {},
  },
}

-- Note on bagIds:
-- Bag -2 is supposed to be the keyring according to: https://wow.gamepedia.com/BagID
-- But I was getting weird results like "Light Leather" when scanning that bag.
-- What is the actual keyring id? Idk...
local bagIds = { 0, 1, 2, 3, 4 } -- All the bags to scan for player inventory
local maxBagSlots = 20

-- https://wow.gamepedia.com/API_GetContainerItemInfo
local function getContainerItem(bagId, slot)
  local v1, v2, v3, v4, v5, v6, v7, v8, v9, v10 = GetContainerItemInfo(bagId, slot)
  if not v10 then return end -- Nothing in that slot
  local itemName = GetItemInfo(v10)

  local itemInfo = {
    bagId = bagId,
    slot = slot,
    order = (bagId * maxBagSlots) + slot,

    icon = v1,        -- fileID (number)
    itemCount = v2,   -- (number)
    locked = v3,      -- true if file is locked by the server (boolean)
    quality = v4,     -- maps to common, rare, epic, etc (number)
    readable = v5,    -- can the item be read, like a book? (boolean)
    lootable = v6,    -- can the item be looted, like a lockbox? (boolean)
    itemLink = v7,    -- (string)
    isFiltered = v8,  -- is the item greyed out because of an inventory search? (boolean)
    noValue = v9,     -- true if the item has no gold value (boolean)
    itemId = v10,     -- (number)

    itemName = itemName,  -- Localized item name (string)
  }

  return itemInfo
end

local function invSort(a, b) return a.order < b.order end
local function contSort(a, b) return a.itemId < b.itemId end
local function updatePlayerInventory()
  -- Reset the existing inventory and its indexes
  local slotList, nameList, idList = {}, {}, {}
  playerInventory.bySlot.list = slotList
  playerInventory.byName.list = nameList
  playerInventory.byId.list = idList
  -- Reset hash values in case of an unexpected error
  playerInventory.bySlot.hash = 0
  playerInventory.byId.hash = 0

  for _, bagId in ipairs(bagIds) do
    for slot = 0, maxBagSlots do
      local itemInfo = getContainerItem(bagId, slot)
      if itemInfo then
        -- Index by container slot, no additional grouping necessary
        slotList[#slotList+1] = itemInfo

        -- Check if this item is indexed by id, if not then initialize all indexes
        local existing = idList[itemInfo.itemId]
        if not existing then
          existing = {
            itemId = itemInfo.itemId,
            itemName = itemInfo.itemName,
            itemCount = 0,
          }
          -- Use the same table ref for both name and id indexes
          idList[itemInfo.itemId] = existing
          nameList[itemInfo.itemName] = existing
        end

        existing.itemCount = existing.itemCount + itemInfo.itemCount
      end
    end
  end

  -- Sort the player's inventory by its "absolute" bag slot
  table.sort(playerInventory, invSort)
  playerInventory.bySlot.hash = addon:GetTableHash(playerInventory)

  -- Sort the inventory's contents by its itemId
  -- Needs to be sorted consistently in order for hash values to be consistent
  -- So put the items in an array then sort by id
  local hashable = {}
  for _, item in pairs(idList) do
    hashable[#hashable+1] = item
  end
  table.sort(hashable, contSort)
  playerInventory.byId.hash = addon:GetTableHash(hashable)
end

--- Gets the player's inventory sorted by how it appears in their bags.
--- @return table array of items
function addon:GetPlayerInventory()
  return playerInventory.bySlot.list
end

--- Gets a table of the different items in the player's bags and the quantities of each.
--- Items that span across multiple bag slots will be grouped together and counted.
--- @return table { ['Hearthstone'] = 1, ['Linen Cloth'] = 120, ... }
function addon:GetPlayerInventoryContents()
  return playerInventory.byId.list
end

--- Returns the number of this specific item in the player's inventory.
--- @param itemNameOrId string or number, the item to search for
--- @return number the number of that item the player has
function addon:GetPlayerItemQuantity(itemNameOrId)
  assert(playerInventory.loaded, "Failed to GetPlayerItemQuantity: player inventory is not loaded")
  assert(itemNameOrId, "Failed to GetPlayerItemQuantity: itemNameOrId is required")

  local item = playerInventory.byId.list[itemNameOrId] or playerInventory.byName.list[itemNameOrId]
  if not item then
    return 0 -- Item not found
  end

  return item.itemCount
end

-- Build the player's inventory when the addon first loads
addon:OnBackendStart(function()
  updatePlayerInventory()
  playerInventory.loaded = true

  -- Then on every update, scan the inventory again and check if its contents changed
  addon.GameEvents:Subscribe("BAG_UPDATE_DELAYED", function()
    local prevHash = playerInventory.byId.hash
    updatePlayerInventory()
    local newHash = playerInventory.byId.hash
    if prevHash ~= newHash then
      logger:Trace("Player inventory contents changed (hash: %.0f)", newHash)
      addon.AppEvents:Publish("PlayerInventoryChanged")
      if didJustLoot then
        didJustLoot = false
        addon.AppEvents:Publish("PlayerLootedItem")
      end
    else
      logger:Trace("Player inventory updated, but no change (hash: %.0f)", newHash)
    end
  end)
  addon.GameEvents:Subscribe("LOOT_SLOT_CLEARED", function()
    didJustLoot = true
  end)
end)
