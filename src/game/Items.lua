local _, addon = ...
local logger = addon.Logger:NewLogger("Items")

local GetItemInfo, GetItemInfoInstant = addon.G.GetItemInfo, addon.G.GetItemInfoInstant

-- Keep a cache of all known item information as it's requested
local cache = {}
local itemInfoSubscribers = {}

-- Based on: https://wow.gamepedia.com/API_GetItemInfo
local function parseFullInfo(id, item)
  item = item or {}
  local full = { GetItemInfo(id) }

  if not full[1] then
    -- Info not yet available on client, but will come back from server
    return
  end

  item.full = true -- Mark that this object contains the complete item info

  item.name = full[1]
  item.link = full[2]
  item.rarity = full[3]
  item.level = full[4]
  item.minLevel = full[5]
  item.type = full[6] -- instant
  item.subType = full[7] -- instant
  item.stackCount = full[8]
  item.equipLoc = full[9] -- instant
  item.icon = full[10] -- instant
  item.sellPrice = full[11]
  item.classId = full[12] -- instant
  item.subClassId = full[13] -- instant
  item.bindType = full[14]
  item.expacId = full[15]
  item.itemSetId = full[16]
  item.isCraftingReagent = full[17]

  return item
end

-- Based on: https://wow.gamepedia.com/API_GetItemInfoInstant
local function parseInstantInfo(id, item)
  item = item or {}
  local instant = { GetItemInfoInstant(id) }

  if not instant[1] then
    -- Item not found, presumably?
    return
  end

  item.id = instant[1] -- not returned on full info, suprisingly
  item.type = instant[2]
  item.subType = instant[3]
  item.equipLoc = instant[4]
  item.icon = instant[5]
  item.classId = instant[6]
  item.subClassId = instant[7]

  return item
end

local function getItem(id)
  -- todo: item lookups by name are very inconsistent
  -- seems like you need to have encountered an item before a name lookup will work
  local cached = cache[id]
  if cached and cached.full then
    -- Full item info is available, return now
    addon.AppEvents:Publish("ItemInfoAvailable", cached)
    return cached
  end

  local item = {}

  local instant = parseInstantInfo(id, item)
  if not instant then return end -- item not found

  local full = parseFullInfo(id, item)
  if full then
    -- Full item info is available, cache the response
    cache[id] = item
    cache[item.id] = item
    cache[item.name] = item
    cache[item.link] = item

    logger:Trace("Item cached: %s (%i)", item.name, item.id)
    addon.AppEvents:Publish("ItemInfoAvailable", item)
  end

  return item
end

--- Empties all cached items from this session
function addon:ClearItemCache()
  logger:Debug("Item cache cleared")
  cache = {}
end

--- Gets all known info about this item id, name, or link.
--- If some data is missing, a server request will be initiated to get the remainder.
--- If this is not a valid item id, name, or link, an error will be thrown.
--- @param idOrName string (or number) the item id, name, or link
function addon:LookupItem(idOrName)
  assert(type(idOrName) == "string" or type(idOrName) == "number", "idOrName must be a number or string")

  local item = getItem(idOrName)
  assert(item, "Unknown item: "..idOrName)

  return item
end

--- Same as LookupItem, but will return nil instead of throwing an error if the item was not found.
--- @param idOrName string (or number) the item id, name, or link
function addon:LookupItemSafe(idOrName)
  assert(idOrName ~= nil, "idOrName must not be nil")
  assert(type(idOrName) == "string" or type(idOrName) == "number", "itemId must be a number or string")
  return getItem(idOrName)
end

--- Performs an async item lookup.
--- @param id string (or number) the item id, name, or link
--- @param handler function function to handle an item (info) object
function addon:OnItemInfoAvailable(id, handler)
  local item
  addon:catch(function()
    item = addon:LookupItem(id)
  end)

  if item then
    -- This only works if AppEvents is async, since the event is published in code
    -- before this subscriber is added to the list
    itemInfoSubscribers[id] = handler
  end
end

addon.GameEvents:Subscribe("GET_ITEM_INFO_RECEIVED", function(itemId, success)
  if success then
    local item = getItem(itemId)
    addon.AppEvents:Publish("ItemInfoAvailable", item)
  end
end)

addon.AppEvents:Subscribe("ItemInfoAvailable", function(item)
  local rem = {}

  for id, handler in pairs(itemInfoSubscribers) do
    if item.id == id or item.name == id or item.link == id then
      handler(item)
      rem[id] = handler
    end
  end

  for id, handler in pairs(rem) do
    itemInfoSubscribers[id] = nil
  end
end)