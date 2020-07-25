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
  print = print,
  strjoin = strjoin,
  strsplit = strsplit,
  time = time,
  unpack = unpack,

  CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo,
  CreateFrame = CreateFrame,
  GetBestMapForUnit = C_Map.GetBestMapForUnit,
  GetMapInfo = C_Map.GetMapInfo,
  GetPlayerMapPosition = C_Map.GetPlayerMapPosition,
  GetUnitName = GetUnitName,
  GetRealZoneText = GetRealZoneText,
  GetSubZoneText = GetSubZoneText,
  GetMinimapZoneText = GetMinimapZoneText,
  GetZoneText = GetZoneText,
  PlaySoundFile = PlaySoundFile,
  ReloadUI = ReloadUI,
  SlashCmdList = SlashCmdList,
  StaticPopupDialogs = StaticPopupDialogs,
  StaticPopup_Show = StaticPopup_Show,
  StaticPopup_Hide = StaticPopup_Hide,
  UnitClass = UnitClass,
  UnitExists = UnitExists,
  UnitFactionGroup = UnitFactionGroup,
  UnitGUID = UnitGUID,
  UnitIsFriend = UnitIsFriend,
  UnitLevel = UnitLevel,
  UIErrorsFrame = UIErrorsFrame,
  UIParent = UIParent,
  UISpecialFrames = UISpecialFrames,
}