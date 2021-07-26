local _, addon = ...
local logger = addon.Logger:NewLogger("Items")
local GameItemCache = addon.GameItemCache
local GetItemInfo, GetItemInfoInstant = addon.G.GetItemInfo, addon.G.GetItemInfoInstant

-- Keep track of every handler that's waiting on item info to be available
local itemInfoSubscribers = {}

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

  item.itemId = instant[1] -- not returned on full info, suprisingly
  item.type = instant[2]
  item.subType = instant[3]
  item.equipLoc = instant[4]
  item.icon = instant[5]
  item.classId = instant[6]
  item.subClassId = instant[7]

  return item
end

local function getItem(idOrName)
  local itemId, itemName = addon:ParseIdOrName(idOrName)

  if not itemId and itemName then
    -- If given a name, prefer the id if we have it cached
    itemId = GameItemCache:FindItemID(itemName)
  end

  local item = {}

  local instant = parseInstantInfo(itemId or itemName, item)
  if not instant then return end -- item not found

  local full = parseFullInfo(itemId or itemName, item)
  if full then
    addon.AppEvents:Publish("ItemInfoAvailable", item)
  end

  return item
end

--- Gets all known info about this item id, name, or link.
--- If some data is missing, a server request will be initiated to get the remainder.
--- If this is not a valid item id, name, or link, an error will be thrown.
--- @param idOrName string (or number) the item id, name, or link
function addon:LookupItem(idOrName)
  addon:ParseIdOrName(idOrName)

  local item = getItem(idOrName)
  assert(item, "Unknown item: "..idOrName)

  return item
end

--- Same as LookupItem, but will return nil instead of throwing an error if the item was not found.
--- @param idOrName string (or number) the item id, name, or link
function addon:LookupItemSafe(idOrName)
  addon:ParseIdOrName(idOrName)
  return getItem(idOrName)
end

--- Performs an async item lookup that will only resolve if or when the full item info is available.
--- @param idOrName string (or number) the item id or name
--- @param handler function function to handle an item (info) object
--- @return table the currently available item info, or nil if not found
function addon:LookupItemAsync(idOrName, handler)
  local itemId, itemName = addon:ParseIdOrName(idOrName)

  local handlerKey = itemId or itemName:lower()
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

local scanData

--- Scans for ALL items by ID by simply starting at ID 1 and counting up.
--- Performs only request one item at a time - doesn't start looking up the next item
--- until the current async request has finished.
function addon:ScanItems(min, max)
  if scanData then
    addon.Logger:Warn("Scan already in progress: currently on %i (%i items found)", scanData.id, scanData.total)
    return
  end

  -- This default max is based on a query from: https://wow-query.dev/
  -- The actual max for classic seems to be somewhere around 25000
  local maxPossibleItemId = 184843

  min = addon:ConvertValue(min or 1, "number")
  max = addon:ConvertValue(max or maxPossibleItemId, "number")
  assert(min and max, "A valid min and max value must be provided")

  scanData = {
    total = 0,
    timeoutTotal = 0,
    min = min,
    max = max,
    id = min - 1,
  }

  addon.Logger:Warn("Beginning item scan - /reload to cancel...")

  local lookupNextItem
  local timeoutHandlerId
  local logInterval = addon.Config:GetValue("ITEM_SCAN_LOG_INTERVAL")
  local asyncTimeout = addon.Config:GetValue("ITEM_SCAN_TIMEOUT")

  if logInterval < 1 then logInterval = maxPossibleItemId end

  local function handleItem(item)
    -- Cancel any timeout handlers because... it didn't timeout!
    addon.Ace:CancelTimer(timeoutHandlerId)
    timeoutHandlerId = nil

    -- Resume scanning now that we're positive the item has been fully defined (and therefore cached)
    scanData.total = scanData.total + 1
    if scanData.total % logInterval == 0 then
      addon.Logger:Warn("Scanning items, %i found...", scanData.total)
    end
    lookupNextItem(item.itemId)
  end

  lookupNextItem = function(id)
    if not id then
      addon.Logger:Warn("Stopping scan: itemId is nil")
    else
      while id < scanData.max do
        id = id + 1
        scanData.id = id -- for logging only
        if addon:LookupItemAsync(id, handleItem) then
          -- Found a real item (stub), stop scanning until it's fully available
          logger:Trace("Scanning for item: %i", id)
          timeoutHandlerId = addon.Ace:ScheduleTimer(function()
            logger:Trace("Item lookup timed out: %i", id)
            timeoutHandlerId = nil
            scanData.timeoutTotal = scanData.timeoutTotal + 1

            -- If the item timed out, remove the subscriber from memory...
            itemInfoSubscribers[id] = nil
            -- ...and move on to the next item
            lookupNextItem(id)
          end, asyncTimeout)
          return
        end
      end
    end

    addon.Logger:Warn("Item scan finished: %i items found (%i timed out).", scanData.total, scanData.timeoutTotal)
    scanData = nil
  end

  -- Kick off the scan!
  lookupNextItem(scanData.id)
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
  handleSubscribers(item.itemId, item)
  handleSubscribers(item.name:lower(), item)
end)