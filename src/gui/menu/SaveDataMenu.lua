local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local menu = addon.MainMenu:NewMenuScreen("SaveDataMenu")

local refreshActions = {}

local function refresh()
  for _, action in ipairs(refreshActions) do
    action()
  end
end

local function createButton(parent, text, width, handler)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetText(text)
  button:SetWidth(width)
  button:SetScript("OnClick", handler)
  return button
end

local function createFontString(parent, text, onRefresh)
  local fs = parent:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall")
  fs:SetText(text)

  if onRefresh then
    refreshActions[#refreshActions+1] = function()
      fs:SetText(string.format(text, onRefresh()))
    end
  end

  return fs
end

local function placeFrame(frame, prevFrame, vertical, spacing)
  spacing = spacing or 8
  if vertical then
    frame:SetPoint("TOPLEFT", prevFrame, "BOTTOMLEFT", 0, -1*spacing)
  else
    frame:SetPoint("TOPLEFT", prevFrame, "TOPRIGHT", spacing, 0)
  end
end

local function clearCache(repository)
  local count = repository:CountAll()
  repository:DeleteAll()
  addon.Logger:Warn("Cleared %s [%i entries]", repository.name, count)
  refresh()
end

local function printPlayerData()
  local cache = addon.PlayerDataCache:FindAll()
  local currentRealm = addon:GetPlayerRealm()

  addon.Logger:Warn("=== Player Data Cache (%i entries) ===", addon.PlayerDataCache:CountAll())

  for _, player in ipairs(cache) do
    local name = player.Name
    if player.Realm and player.Realm ~= currentRealm then name = player.FullName end
    if player.Guild then name = name.." <"..player.Guild..">" end
    name = addon:Colorize("yellow", name)

    local faction = player.FactionId
    if faction == "Horde" then faction = addon:Colorize("red", "[H]")
    elseif faction == "Alliance" then faction = addon:Colorize("cyan", "[A]")
    else faction = "" end

    local level = tostring(player.Level) or "??"
    local sex = player.SexId and addon:GetSexNameById(player.SexId) or ""
    local race = player.RaceId and addon:GetRaceNameById(player.RaceId) or ""
    local class = player.ClassId and addon:GetClassNameById(player.ClassId) or ""

    addon.Logger:Info("%s: %s Level %s %s %s %s",
      name, faction, level, sex, race, class)
  end
end

local function printNpcData()
  local cache = addon.NpcDataCache:FindAll()

  addon.Logger:Warn("=== NPC Data Cache (%i entries) ===", addon.NpcDataCache:CountAll())

  for _, npc in ipairs(cache) do
    local name = addon:Colorize("yellow", npc.Name)

    local faction = npc.FactionId
    if faction == "Horde" then faction = addon:Colorize("red", "[H]")
    elseif faction == "Alliance" then faction = addon:Colorize("cyan", "[A]")
    else faction = "" end

    local level
    if npc.LevelMin and npc.LevelMax and npc.LevelMin ~= npc.LevelMax then
      level = string.format("%i-%i", npc.LevelMin, npc.LevelMax)
    elseif npc.Level then
      level = tostring(npc.Level)
    else
      level = "??"
    end

    addon.Logger:Info("%s: %s Level %s",
      name, faction, level)
  end
end

function menu:Create(frame)
  frame:SetScript("OnShow", refresh)

  -- Player Data

  local playerDataHeader = createFontString(frame, "Player Data Cache (%i entries)",
    function() return addon.PlayerDataCache:CountAll() end)
  playerDataHeader:SetPoint("TOPLEFT", frame, "TOPLEFT")

  local printPlayerDataButton = createButton(frame, "Print All", 80, printPlayerData)
  placeFrame(printPlayerDataButton, playerDataHeader, true)

  local clearPlayerDataButton = createButton(frame, "Delete All", 80,
    function() clearCache(addon.PlayerDataCache) end)
  placeFrame(clearPlayerDataButton, printPlayerDataButton)

  -- NPC Data

  local npcDataHeader = createFontString(frame, "NPC Data Cache (%i entries)",
    function() return addon.NpcDataCache:CountAll() end)
  placeFrame(npcDataHeader, printPlayerDataButton, true, 20)

  local printNpcDataButton = createButton(frame, "Print All", 80, printNpcData)
  placeFrame(printNpcDataButton, npcDataHeader, true)

  local clearNpcDataButton = createButton(frame, "Delete All", 80,
    function() clearCache(addon.NpcDataCache) end)
  placeFrame(clearNpcDataButton, printNpcDataButton)

  -- Item Data

  local itemDataHeader = createFontString(frame, "Item Data Cache (%i entries)",
    function() return addon.GameItemCache:CountAll() end)
  placeFrame(itemDataHeader, printNpcDataButton, true, 20)

  local lookupItemInput = addon.CustomWidgets:CreateWidget("TextInput", frame, "Item Name or ID")
  lookupItemInput:SetWidth(200)
  placeFrame(lookupItemInput, itemDataHeader, true)

  local lookupItemButton = createButton(frame, "Search", 60,
    function()
      local inputText = lookupItemInput:GetText()
      if inputText and inputText ~= "" then
        addon:RunSlashCommand("lookup-item", inputText)
      end
      refresh()
    end)
  lookupItemButton:SetPoint("TOPLEFT", lookupItemInput, "TOPRIGHT")
  lookupItemButton:SetPoint("BOTTOMLEFT", lookupItemInput, "BOTTOMRIGHT")
  placeFrame(lookupItemButton, lookupItemInput)

  lookupItemInput.onSubmit = function() lookupItemButton:Click() end

  local scanItemButton = createButton(frame, "Begin Scan", 80,
    function() addon:RunSlashCommand("scan-items") end)
  placeFrame(scanItemButton, lookupItemInput, true)

  local clearItemDataButton = createButton(frame, "Delete All", 80,
    function() clearCache(addon.GameItemCache) end)
  placeFrame(clearItemDataButton, scanItemButton)

  -- Spells

  local spellDataHeader = createFontString(frame, "Spell Data Cache (%i entries)",
    function() return addon.GameSpellCache:CountAll() end)
  placeFrame(spellDataHeader, scanItemButton, true, 20)

  local lookupSpellInput = addon.CustomWidgets:CreateWidget("TextInput", frame, "Spell Name or ID")
  lookupSpellInput:SetWidth(200)
  placeFrame(lookupSpellInput, spellDataHeader, true)

  local lookupSpellButton = createButton(frame, "Search", 60,
    function()
      local inputText = lookupSpellInput:GetText()
      if inputText and inputText ~= "" then
        addon:RunSlashCommand("lookup-spell", inputText)
      end
      refresh()
    end)
  lookupSpellButton:SetPoint("TOPLEFT", lookupSpellInput, "TOPRIGHT")
  lookupSpellButton:SetPoint("BOTTOMLEFT", lookupSpellInput, "BOTTOMRIGHT")
  placeFrame(lookupSpellButton, lookupSpellInput)

  lookupSpellInput.onSubmit = function() lookupSpellButton:Click() end

  local scanSpellButton = createButton(frame, "Begin Scan", 80,
    function() addon:RunSlashCommand("scan-spells") end)
  placeFrame(scanSpellButton, lookupSpellInput, true)

  local clearSpellDataButton = createButton(frame, "Delete All", 80,
    function() clearCache(addon.GameSpellCache) end)
  placeFrame(clearSpellDataButton, scanSpellButton)

  -- Other

  local otherHeader = createFontString(frame, "Other Save Data Settings")
  placeFrame(otherHeader, scanSpellButton, true, 20)

  local resetFramesButton = createButton(frame, "Reset Frame Positions", 200,
    function()
      -- todo: Come up with some way to grab all PopoutFrames and reset them
      addon.LocationFinderFrame:ResetWindowState()
      addon.EmoteFrame:ResetWindowState()
      addon.QuestLogFrame:ResetWindowState()
      addon.Config:SaveValue("FrameData", {})
      addon.Logger:Warn("Frame positions reset.")
    end)
  placeFrame(resetFramesButton, otherHeader, true)

  local resetAllButton = createButton(frame, "Reset All Save Data", 200,
    function() addon.StaticPopups:Show("ResetSaveData") end)
  placeFrame(resetAllButton, resetFramesButton, true)

  refresh()
end