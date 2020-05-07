local _, addon = ...

-- Libraries
addon.Ace = LibStub("AceAddon-3.0"):NewAddon("PlayerMadeQuests", "AceEvent-3.0", "AceSerializer-3.0", "AceTimer-3.0")
addon.AceGUI = LibStub("AceGUI-3.0")
addon.LibCompress = LibStub("LibCompress")

-- WoW Global Functions
addon.G = {
  strjoin = strjoin,
  strsplit = strsplit,
  time = time,
  unpack = unpack,

  CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo,
  GetUnitName = GetUnitName,
  SlashCmdList = SlashCmdList,
  UnitExists = UnitExists,
  UnitGUID = UnitGUID,
  UnitIsFriend = UnitIsFriend,
  UISpecialFrames = UISpecialFrames,
  UIParent = UIParent,
}