local mock = require("spec/mock")

local game = {}

-- Keep track of mocked functions so they can be reset
local mocks = {}

local function unitIdIsTarget(uid) return uid == "target" end
local function unitIdIsPlayer(uid) return uid == "player" end
local function firstArgEquals(value)
  return function(arg0) return arg0 == value end
end

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
  mock:GetFunctionMock(addon.G.UnitIsPlayer):SetReturnsWhen(unitIdIsTarget, true)
  mock:GetFunctionMock(addon.G.UnitExists):SetReturnsWhen(unitIdIsTarget, true)
  mocks[#mocks+1] = addon.G.GetUnitName
  mocks[#mocks+1] = addon.G.UnitGUID
  mocks[#mocks+1] = addon.G.UnitIsPlayer
  mocks[#mocks+1] = addon.G.UnitExists
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

  mock:GetFunctionMock(addon.G.IsEquippedItem):SetReturnsWhen(firstArgEquals(item.name), true)
  mocks[#mocks+1] = addon.G.IsEquippedItem
end

function game:SetPlayerInfo(addon, info)
  assert(type(info) == "table", "SetPlayerInfo must receive a table")

  if info.name or info.realm then
    local name = info.name or "PlayerName"
    local realm = info.realm or "PlayerRealm"

    mock:GetFunctionMock(addon.G.GetUnitName):SetReturnsWhen(unitIdIsPlayer, name)
    mock:GetFunctionMock(addon.G.UnitFullName):SetReturnsWhen(unitIdIsPlayer, name, realm)
    mocks[#mocks+1] = addon.G.GetUnitName
    mocks[#mocks+1] = addon.G.UnitFullName
  end

  if info.level then
    mock:GetFunctionMock(addon.G.UnitLevel):SetReturnsWhen(unitIdIsPlayer, info.level)
    mocks[#mocks+1] = addon.G.UnitLevel
  end

  if info.class then
    mock:GetFunctionMock(addon.G.UnitClass):SetReturnsWhen(unitIdIsPlayer, info.class, nil, info.classId)
    mocks[#mocks+1] = addon.G.UnitClass

    if info.classId then
      mock:GetFunctionMock(addon.G.GetClassInfo):SetReturnsWhen(firstArgEquals(info.classId), { className = info.class })
      mocks[#mocks+1] = addon.G.GetClassInfo
    end
  end

  if info.faction then
    mock:GetFunctionMock(addon.G.UnitFactionGroup):SetReturnsWhen(unitIdIsPlayer, info.faction, info.faction)
    mocks[#mocks+1] = addon.G.UnitFactionGroup
  end

  if info.race then
    mock:GetFunctionMock(addon.G.UnitRace):SetReturnsWhen(unitIdIsPlayer, info.race, nil, info.raceId)
    mocks[#mocks+1] = addon.G.UnitRace

    if info.raceId then
      mock:GetFunctionMock(addon.G.GetRaceInfo):SetReturnsWhen(firstArgEquals(info.raceId), { raceName = info.race })
      mocks[#mocks+1] = addon.G.GetRaceInfo
    end
  end

  if info.sex then
    mock:GetFunctionMock(addon.G.UnitSex):SetReturnsWhen(unitIdIsPlayer, info.sex)
    mocks[#mocks+1] = addon.G.UnitSex
  end

  if info.guild then
    mock:GetFunctionMock(addon.G.GetGuildInfo):SetReturnsWhen(unitIdIsPlayer, info.guild)
    mocks[#mocks+1] = addon.G.GetGuildInfo
  end
end

function game:SetPlayerGroup(addon, groupType)
  local isInGroup = groupType == "PARTY" or groupType == "RAID"
  local isInRaid = groupType == "RAID"

  mock:GetFunctionMock(addon.G.IsInGroup):SetReturns(isInGroup)
  mock:GetFunctionMock(addon.G.IsInRaid):SetReturns(isInRaid)
  mocks[#mocks+1] = addon.G.IsInRaid
  mocks[#mocks+1] = addon.G.IsInGroup
end

function game:SetSpellName(addon, spellId, spellName)
  assert(type(spellId) == "number", "SetSpellInfo must receive a spellId")
  assert(type(spellName) == "string", "SetSpellInfo must receive a spellName")

  mock:GetFunctionMock(addon.G.GetSpellInfo):SetReturnsWhen(
    function(arg) return arg == spellId or arg == spellName end,
    spellName, nil, nil, nil, nil, nil, spellId)

  mocks[#mocks+1] = addon.G.GetSpellInfo
end

return game