local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local menu = addon.MainMenu:NewMenuScreen("SaveDataMenu")

local function placeButton(button, prevButton)
  button:SetPoint("TOPLEFT", prevButton, "BOTTOMLEFT", 0, -8)
  button:SetPoint("TOPRIGHT", prevButton, "BOTTOMRIGHT", 0, -8)
end

function menu:Create(frame)
  local clearPlayerDataButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  clearPlayerDataButton:SetText("Clear Player Data Cache")
  clearPlayerDataButton:SetScript("OnClick", function()
    local cache = addon.PlayerDataCache:FindAll()
    addon.PlayerDataCache:DeleteAll()
    addon.Logger:Warn("Flushed player data cache [%i players]", addon:tlen(cache))
  end)
  clearPlayerDataButton:SetWidth(200)
  clearPlayerDataButton:SetPoint("TOPLEFT", frame, "TOPLEFT")

  local clearNpcDataButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  clearNpcDataButton:SetText("Clear NPC Data Cache")
  clearNpcDataButton:SetScript("OnClick", function()
    local cache = addon.NpcDataCache:FindAll()
    addon.NpcDataCache:DeleteAll()
    addon.Logger:Warn("Flushed NPC data cache [%i NPCs]", addon:tlen(cache))
  end)
  placeButton(clearNpcDataButton, clearPlayerDataButton)

  local clearItemDataButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  clearItemDataButton:SetText("Clear Item Data Cache")
  clearItemDataButton:SetScript("OnClick", function()
    local cache = addon.GameItemCache:FindAll()
    addon.GameItemCache:DeleteAll()
    addon.Logger:Warn("Flushed item data cache [%i items]", addon:tlen(cache))
  end)
  placeButton(clearItemDataButton, clearNpcDataButton)

  local clearSpellDataButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  clearSpellDataButton:SetText("Clear Spell Data Cache")
  clearSpellDataButton:SetScript("OnClick", function()
    local cache = addon.GameSpellCache:FindAll()
    addon.GameSpellCache:DeleteAll()
    addon.Logger:Warn("Flushed spell data cache [%i items]", addon:tlen(cache))
  end)
  placeButton(clearSpellDataButton, clearItemDataButton)

  local resetFramesButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  resetFramesButton:SetText("Reset Frame Positions")
  resetFramesButton:SetScript("OnClick", function()
    -- todo: Come up with some way to grab all PopoutFrames and reset them
    addon.LocationFinderFrame:ResetWindowState()
    addon.EmoteFrame:ResetWindowState()
    addon.QuestLogFrame:ResetWindowState()
    addon.Config:SaveValue("FrameData", {})
    addon.Logger:Warn("Frame positions reset.")
  end)
  placeButton(resetFramesButton, clearSpellDataButton)

  local resetAllButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  resetAllButton:SetText("Reset All Save Data")
  resetAllButton:SetScript("OnClick", function()
    addon.StaticPopups:Show("ResetSaveData")
  end)
  placeButton(resetAllButton, resetFramesButton)
end