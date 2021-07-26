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

  AddMessageEventFilter = ChatFrame_AddMessageEventFilter,
  CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo,
  CheckInteractDistance = CheckInteractDistance,
  CreateFrame = CreateFrame,
  GameTooltip = GameTooltip,
  GetBestMapForUnit = C_Map.GetBestMapForUnit,
  GetBuildInfo = GetBuildInfo,
  GetCoinTextureString = GetCoinTextureString,
  GetClassInfo = C_CreatureInfo.GetClassInfo,
  GetGuildInfo = GetGuildInfo,
  GetMapInfo = C_Map.GetMapInfo,
  GetPlayerMapPosition = C_Map.GetPlayerMapPosition,
  GetUnitName = GetUnitName,
  GetRaceInfo = C_CreatureInfo.GetRaceInfo,
  GetRealZoneText = GetRealZoneText,
  GetSpellInfo = GetSpellInfo,
  GetSubZoneText = GetSubZoneText,
  GetMinimapZoneText = GetMinimapZoneText,
  GetZoneText = GetZoneText,
  GetItemInfo = GetItemInfo,
  GetItemInfoInstant = GetItemInfoInstant,
  GetContainerItemInfo = GetContainerItemInfo,
  GetInventorySlotInfo = GetInventorySlotInfo,
  GetInventoryItemID = GetInventoryItemID,
  GetPlayerTradeMoney = GetPlayerTradeMoney,
  GetTradePlayerItemInfo = GetTradePlayerItemInfo,
  GetTargetTradeMoney = GetTargetTradeMoney,
  GetTradeTargetItemInfo = GetTradeTargetItemInfo,
  IsEquippedItem = IsEquippedItem,
  IsInGroup = IsInGroup,
  IsInGuild = IsInGuild,
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
  UnitIsPlayer = UnitIsPlayer,
  UnitLevel = UnitLevel,
  UnitRace = UnitRace,
  UnitSex = UnitSex,
  UIErrorsFrame = UIErrorsFrame,
  UIParent = UIParent,
  UISpecialFrames = UISpecialFrames,

  -- Undocumented global functions for working with ItemButtons
  -- See here: https://github.com/Gethe/wow-ui-source/blob/classic/FrameXML/ItemButtonTemplate.lua
  SetItemButtonCount = SetItemButtonCount,
  SetItemButtonStock = SetItemButtonStock,
  SetItemButtonTexture = SetItemButtonTexture,
  SetItemButtonTextureVertexColor = SetItemButtonTextureVertexColor,
  SetItemButtonDesaturated = SetItemButtonDesaturated,
  SetItemButtonNormalTextureVertexColor = SetItemButtonNormalTextureVertexColor,
  SetItemButtonNameFrameVertexColor = SetItemButtonNameFrameVertexColor,
  SetItemButtonSlotVertexColor = SetItemButtonSlotVertexColor,
  SetItemButtonQuality = SetItemButtonQuality,
  HandleModifiedItemClick = HandleModifiedItemClick,

  -- Mixins
  Mixin = Mixin,
  CreateFromMixins = CreateFromMixins,
  CreateAndInitFromMixin = CreateAndInitFromMixin,
  BackdropTemplateMixin = BackdropTemplateMixin,

  -- Global functions for managing dropdown menus
  UIDropDownMenu_Initialize = UIDropDownMenu_Initialize,
  UIDropDownMenu_SetWidth = UIDropDownMenu_SetWidth,
  UIDropDownMenu_SetText = UIDropDownMenu_SetText,
  UIDropDownMenu_CreateInfo = UIDropDownMenu_CreateInfo,
  UIDropDownMenu_SetSelectedValue = UIDropDownMenu_SetSelectedValue,
  UIDropDownMenu_AddButton = UIDropDownMenu_AddButton,

  PanelTemplates_SetDisabledTabState = PanelTemplates_SetDisabledTabState,
  PanelTemplates_SelectTab = PanelTemplates_SelectTab,
  PanelTemplates_DeselectTab = PanelTemplates_DeselectTab,
  PanelTemplates_TabResize = PanelTemplates_TabResize,
}