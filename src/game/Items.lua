local _, addon = ...
local logger = addon.Logger:NewLogger("Items")
local GameItemCache = addon.GameItemCache
local GetItemInfo, GetItemInfoInstant = addon.G.GetItemInfo, addon.G.GetItemInfoInstant

-- Keep a cache of all known item information as it's requested
local cache = {}
local itemInfoSubscribers = {}

--- Returns either the itemId as a number, or the all-lowercase item name
local function parseIdOrName(idOrName)
  local itemId, itemName

  if type(idOrName) == "number" then
    itemId = idOrName
  elseif type(idOrName) == "string" then
    itemId = tonumber(idOrName)
    if not itemId then
      itemName = idOrName:lower()
    end
  else
    if idOrName == nil then
      error("Item idOrName must not be nil", 2)
    end
    error("Item idOrName must be a number or string", 2)
  end

  return itemId, itemName
end

-- Based on: https://wow.gamepedia.com/API_GetItemInfo
local function parseFullInfo(idOrName, item)
  item = item or {}
  local full = { GetItemInfo(idOrName) }

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
local function parseInstantInfo(idOrName, item)
  item = item or {}
  local instant = { GetItemInfoInstant(idOrName) }

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

local function getItem(idOrName)
  local itemId, itemName = parseIdOrName(idOrName)

  if not itemId and itemName then
    -- If given a name, prefer the id if we have it cached
    itemId = GameItemCache:FindItemID(itemName)
  end

  local cached = cache[itemId]
  if cached and cached.full then
    -- Full item info is available, return now
    addon.AppEvents:Publish("ItemInfoAvailable", cached)
    return cached
  end

  local item = {}

  local instant = parseInstantInfo(itemId or itemName, item)
  if not instant then return end -- item not found

  local full = parseFullInfo(itemId or itemName, item)
  if full then
    -- Full item info is available, cache the response
    cache[item.id] = item

    logger:Trace("Item cached: %s (%i)", item.name, item.id)
    addon.AppEvents:Publish("ItemInfoAvailable", item)
  end

  return item
end

--- Empties all cached items from this session
function addon:ClearItemCache()
  cache = {}
  GameItemCache:DeleteAll()
  logger:Debug("Item cache cleared")
end

--- Gets all known info about this item id, name, or link.
--- If some data is missing, a server request will be initiated to get the remainder.
--- If this is not a valid item id, name, or link, an error will be thrown.
--- @param idOrName string (or number) the item id, name, or link
function addon:LookupItem(idOrName)
  parseIdOrName(idOrName)

  local item = getItem(idOrName)
  assert(item, "Unknown item: "..idOrName)

  return item
end

--- Same as LookupItem, but will return nil instead of throwing an error if the item was not found.
--- @param idOrName string (or number) the item id, name, or link
function addon:LookupItemSafe(idOrName)
  parseIdOrName(idOrName)
  return getItem(idOrName)
end

--- Performs an async item lookup that will only resolve if or when the full item info is available.
--- @param idOrName string (or number) the item id or name
--- @param handler function function to handle an item (info) object
--- @return table the currently available item info, or nil if not found
function addon:LookupItemAsync(idOrName, handler)
  local itemId, itemName = parseIdOrName(idOrName)

  local handlerKey = itemId or itemName
  local handlers = itemInfoSubscribers[handlerKey]
  if not handlers then
    handlers = {}
    itemInfoSubscribers[handlerKey] = handlers
  end

  handlers[#handlers+1] = handler

  local item
  addon:catch(function()
    item = getItem(idOrName)
  end)

  if not item then
    -- If not even a stub item could be found, then remove the handlers, because it will never be resolved
    handlers[#handlers] = nil
  end

  return item
end

addon.GameEvents:Subscribe("GET_ITEM_INFO_RECEIVED", function(itemId, success)
  if success then
    getItem(itemId) -- this will trigger ItemInfoAvailable to be published
  end
end)

local function handleSubscribers(key, item)
  local handlers = itemInfoSubscribers[key]
  if handlers then
    for _, handler in ipairs(handlers) do
      handler(item)
    end
    itemInfoSubscribers[key] = nil
  end
end

addon.AppEvents:Subscribe("ItemInfoAvailable", function(item)
  handleSubscribers(item.id, item)
  handleSubscribers(item.name:lower(), item)
end)