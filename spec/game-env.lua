local mock = require("spec/mock")

local game = {}

-- Keep track of mocked functions so they can be reset
local mocks = {}

local function unitIdIsTarget(uid) return uid == "target" end
local function unitIdIsPlayer(uid) return uid == "player" end

function game:ResetEnv(addon)
  addon._genv_aura_index = nil
  addon._genv_next_bag_slot = nil

  for _, fn in ipairs(mocks) do
    mock:GetFunctionMock(fn):Reset()
  end
  mocks = {}
end

function game:AddPlayerAura(addon, aura)
  assert(type(aura) == "table", "AddPlayerAura must receive a table")

  local ret = {
    aura.name,
    aura.icon,
    aura.count,
    aura.debuffType,
    aura.duration,
    aura.expirationTime,
    aura.source,
    aura.isStealable,
    aura.nameplateShowPersonal,
    aura.spellId,
    aura.canApplyAura,
    aura.isBossDebuff,
    aura.castByPlayer,
    aura.nameplateShowAll,
    aura.timeMod,
  }

  local index = addon._genv_aura_index or 0
  index = index + 1
  addon._genv_aura_index = index

  mock:GetFunctionMock(addon.G.UnitAura):SetReturnsWhen(function(uid, idx)
    return uid == "player" and idx == index
  end, table.unpack(ret))
  mocks[#mocks+1] = addon.G.UnitAura
end

function game:SetPlayerTarget(addon, target)
  assert(type(target) == "table", "SetPlayerTarget must receive a table")

  target.name = target.name or "Anonymous target"
  target.guid = target.guid or addon:CreateID("unit-guid-%i")

  mock:GetFunctionMock(addon.G.GetUnitName):SetReturnsWhen(unitIdIsTarget, target.name)
  mock:GetFunctionMock(addon.G.UnitGUID):SetReturnsWhen(unitIdIsTarget, target.guid)
  mocks[#mocks+1] = addon.G.GetUnitName
  mocks[#mocks+1] = addon.G.UnitGUID
end

function game:SetPlayerLocation(addon, loc)
  assert(type(loc) == "table", "SetPlayerLocation must receive a table")

  if loc.zone then
    mock:GetFunctionMock(addon.G.GetZoneText):SetReturns(loc.zone)
    mock:GetFunctionMock(addon.G.GetRealZoneText):SetReturns(loc.zone)
    mocks[#mocks+1] = addon.G.GetZoneText
    mocks[#mocks+1] = addon.G.GetRealZoneText
  end
  if loc.subzone then
    mock:GetFunctionMock(addon.G.GetSubZoneText):SetReturns(loc.subzone)
    mock:GetFunctionMock(addon.G.GetMinimapZoneText):SetReturns(loc.subzone)
    mocks[#mocks+1] = addon.G.GetSubZoneText
    mocks[#mocks+1] = addon.G.GetMinimapZoneText
  end
  if loc.x and loc.y then
    -- WoW returns x,y as values between 0 and 1, coerce provided values if necessary
    if loc.x > 1 then loc.x = loc.x / 100 end
    if loc.y > 1 then loc.y = loc.y / 100 end
    local mockMap = {}
    local mockPosition = {
      GetXY = function() return loc.x, loc.y end
    }
    mock:GetFunctionMock(addon.G.GetBestMapForUnit):SetReturnsWhen(unitIdIsPlayer, mockMap)
    mock:GetFunctionMock(addon.G.GetPlayerMapPosition):SetReturnsWhen(function(map, uid)
      return map == mockMap and uid == "player"
    end, mockPosition)
    mocks[#mocks+1] = addon.G.GetBestMapForUnit
    mocks[#mocks+1] = addon.G.GetPlayerMapPosition
  end
end

function game:AddPlayerItem(addon, item)
  assert(type(item) == "table", "AddPlayerItem must receive a table")

  item.itemId = item.itemId or addon:CreateID("item-%i")

  local ret = {
    item.icon,
    item.itemCount or 1,
    item.locked,
    item.quality,
    item.readable,
    item.lootable,
    item.itemLink,
    item.isFiltered,
    item.noValue,
    item.itemId,
  }

  addon._genv_next_bag_slot = addon._genv_next_bag_slot or 1
  local bagslot = addon._genv_next_bag_slot
  addon._genv_next_bag_slot = addon._genv_next_bag_slot + 1
  local bagId = math.floor(bagslot / 20) -- maxBagSlots in Items.lua
  bagslot = bagslot % 20

  mock:GetFunctionMock(addon.G.GetContainerItemInfo):SetReturnsWhen(function(bid, bslot)
    return bid == bagId and bslot == bagslot
  end, table.unpack(ret))
  mocks[#mocks+1] = addon.G.GetContainerItemInfo

  if item.name then
    mock:GetFunctionMock(addon.G.GetItemInfo):SetReturnsWhen(function(id)
      return id == item.itemId
    end, item.name)
  end
  mocks[#mocks+1] = addon.G.GetItemInfo

  addon.GameEvents:Publish("BAG_UPDATE_DELAYED")
  addon:Advance()
end

function game:AddPlayerEquipment(addon, item)
  assert(type(item) == "table", "AddPlayerEquipment must receive a table")

  mock:GetFunctionMock(addon.G.IsEquippedItem):SetReturnsWhen(function(itemIdOrName)
    return itemIdOrName == item.name
  end, true)
  mocks[#mocks+1] = addon.G.IsEquippedItem
end

return game