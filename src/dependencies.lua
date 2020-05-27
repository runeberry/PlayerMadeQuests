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

-- WoW Global Functions
addon.G = {
  print = print,
  strjoin = strjoin,
  strsplit = strsplit,
  time = time,
  unpack = unpack,

  CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo,
  CreateFrame = CreateFrame,
  GetUnitName = GetUnitName,
  PlaySoundFile = PlaySoundFile,
  SlashCmdList = SlashCmdList,
  StaticPopupDialogs = StaticPopupDialogs,
  StaticPopup_Show = StaticPopup_Show,
  StaticPopup_Hide = StaticPopup_Hide,
  UnitExists = UnitExists,
  UnitGUID = UnitGUID,
  UnitIsFriend = UnitIsFriend,
  UIErrorsFrame = UIErrorsFrame,
  UIParent = UIParent,
  UISpecialFrames = UISpecialFrames,
}