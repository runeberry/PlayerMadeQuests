local _, addon = ...

local aceMixins = {
  "AceEvent-3.0",
  "AceSerializer-3.0",
  "AceTimer-3.0",
  "AceComm-3.0"
}

-- Libraries
addon.Ace = LibStub("AceAddon-3.0"):NewAddon("PlayerMadeQuests", unpack(aceMixins))
addon.AceGUI = LibStub("AceGUI-3.0")
addon.LibCompress = LibStub("LibCompress")
addon.LibScrollingTable = LibStub("ScrollingTable")
addon.ParseYaml = LibStub("TinyYaml").parse

-- WoW Global Functions
addon.G = {
  date = date,
  print = print,
  strjoin = strjoin,
  strsplit = strsplit,
  time = time,
  unpack = unpack,

  CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo,
  CheckInteractDistance = CheckInteractDistance,
  CreateFrame = CreateFrame,
  GetBestMapForUnit = C_Map.GetBestMapForUnit,
  GetBuildInfo = GetBuildInfo,
  GetMapInfo = C_Map.GetMapInfo,
  GetPlayerMapPosition = C_Map.GetPlayerMapPosition,
  GetUnitName = GetUnitName,
  GetRealZoneText = GetRealZoneText,
  GetSubZoneText = GetSubZoneText,
  GetMinimapZoneText = GetMinimapZoneText,
  GetZoneText = GetZoneText,
  GetItemInfo = GetItemInfo,
  GetContainerItemInfo = GetContainerItemInfo,
  GetInventorySlotInfo = GetInventorySlotInfo,
  GetInventoryItemID = GetInventoryItemID,
  IsEquippedItem = IsEquippedItem,
  IsInGroup = IsInGroup,
  IsInRaid = IsInRaid,
  PlaySoundFile = PlaySoundFile,
  ReloadUI = ReloadUI,
  SlashCmdList = SlashCmdList,
  StaticPopupDialogs = StaticPopupDialogs,
  StaticPopup_Show = StaticPopup_Show,
  StaticPopup_Hide = StaticPopup_Hide,
  UnitAura = UnitAura,
  UnitClass = UnitClass,
  UnitExists = UnitExists,
  UnitFactionGroup = UnitFactionGroup,
  UnitFullName = UnitFullName,
  UnitGUID = UnitGUID,
  UnitIsFriend = UnitIsFriend,
  UnitLevel = UnitLevel,
  UIErrorsFrame = UIErrorsFrame,
  UIParent = UIParent,
  UISpecialFrames = UISpecialFrames,
}