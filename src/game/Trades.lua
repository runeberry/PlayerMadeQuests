local _, addon = ...
local asserttype = addon.asserttype
local GetPlayerTradeMoney, GetTradePlayerItemInfo = addon.G.GetPlayerTradeMoney, addon.G.GetTradePlayerItemInfo
local GetTargetTradeMoney, GetTradeTargetItemInfo = addon.G.GetTargetTradeMoney, addon.G.GetTradeTargetItemInfo
local GetUnitName, UnitIsPlayer = addon.G.GetUnitName, addon.G.UnitIsPlayer

--[[
  The contents of this file are intended to watch game events and determine when the player has
  successfully traded another character, and publish information about that trade in a
  "PlayerTraded" AppEvent.
--]]

-- Keeps track of the currently active trade
local currentTrade
local tradeClosedTimer
local tradeClosedDelay = 0.2
local numTradeItemSlots = 7

local function getTradeItems(apiFunction)
  local items = {}
  local enchantItem

  for i = 1, numTradeItemSlots, 1 do
    local name, texture, quantity, quality, isUsable, enchant = apiFunction(i)
    if name then
      -- Expecting this item to be cached by name since it's already in the trade window
      local item = addon:LookupItemSafe(name)
      if item then
        -- Extract info relevant to the trade, consumers can lookup more details
        local tradeItem = {
          itemId = item.itemId,
          itemName = item.name,
          quantity = quantity,
          enchant = enchant, -- Should only apply to slot #7
        }
        if i == numTradeItemSlots then
          -- Last trade slot is the item being enchanted, not being traded
          enchantItem = tradeItem
        else
          items[#items+1] = tradeItem
        end
      else
        addon.Logger:Debug("Unable to find item by name: %s", name)
      end
    end
  end

  return items, enchantItem
end

local function updateCurrentTrade()
  if not currentTrade then
    currentTrade = {}
  end

  -- The first player that's targeted during a trade event is assumed to be the trading player
  if not currentTrade.targetName then
    if UnitIsPlayer("target") then
      currentTrade.targetName = GetUnitName("target")
    end
  end

  -- Update the amount of money being traded
  local playerMoney = GetPlayerTradeMoney()
  currentTrade.playerMoney = tonumber(playerMoney)
  local targetMoney = GetTargetTradeMoney()
  currentTrade.targetMoney = tonumber(targetMoney)

  -- Update the items being traded
  local playerItems, playerEnchantItem = getTradeItems(function(i) return GetTradePlayerItemInfo(i) end)
  local targetItems, targetEnchantItem = getTradeItems(function(i) return GetTradeTargetItemInfo(i) end)

  currentTrade.playerItems = playerItems
  currentTrade.playerEnchantItem = playerEnchantItem
  currentTrade.targetItems = targetItems
  currentTrade.targetEnchantItem = targetEnchantItem
end

local function resolveCurrentTrade()
  if not currentTrade then return end

  local accepted
  if currentTrade.cancelled then
    -- We know the trade was cancelled, so it couldn't have gone through
    accepted = false
  elseif currentTrade.closedAccepted then
    -- Assume the trade was accepted because it was "closed" but never "cancelled"
    accepted = true
  elseif currentTrade.playerAccepted and currentTrade.targetAccepted then
    -- We know both players accepted the trade, so it definitely went through
    -- This only happens if the target accepts BEFORE the player
    accepted = true
  else
    -- We can't say for sure whether the trade was successful, so wait to see if a cancellation comes through
    -- This will probably happen if the target accepts AFTER the player
    if tradeClosedTimer then
      -- Already a pending timer, don't resolve yet
      return
    end

    tradeClosedTimer = addon.Ace:ScheduleTimer(function()
      tradeClosedTimer = nil
      if currentTrade then
        -- If there is still a trade cached, then it didn't get resolved by a cancellation.
        currentTrade.closedAccepted = true
        resolveCurrentTrade()
      end
    end, tradeClosedDelay)
  end

  if accepted then
    -- Only publish accepted trades for other systems to consume
    addon.AppEvents:Publish("PlayerTraded", currentTrade)
  end

  -- Remove the current trade from cache, it is now considered resolved
  currentTrade = nil
end

addon.GameEvents:Subscribe("TRADE_ACCEPT_UPDATE", function(playerAccepted, targetAccepted)
  updateCurrentTrade()

  currentTrade.playerAccepted = playerAccepted
  currentTrade.targetAccepted = targetAccepted
end)

addon.GameEvents:Subscribe("TRADE_UPDATE", function()
  updateCurrentTrade()
end)

addon.GameEvents:Subscribe("TRADE_REQUEST_CANCEL", function()
  if not currentTrade then return end

  currentTrade.cancelled = true

  resolveCurrentTrade()
end)

addon.GameEvents:Subscribe("TRADE_CLOSED", function()
  resolveCurrentTrade()
end)