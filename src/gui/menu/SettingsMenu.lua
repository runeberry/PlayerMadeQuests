local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local menu = addon.MainMenu:NewMenuScreen("SettingsMenu")

function menu:Create(frame)
  local resetFramesButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  resetFramesButton:SetText("Reset Frame Positions")
  resetFramesButton:SetScript("OnClick", function()
    -- todo: Come up with some way to grab all PopoutFrames and reset them
    addon.LocationFinderFrame:ResetWindowState()
    addon.QuestLogFrame:ResetWindowState()
    addon.Config:SaveValue("FrameData", {})
    addon.Logger:Warn("Frame positions reset.")
  end)
  resetFramesButton:SetWidth(200)
  resetFramesButton:SetPoint("TOPLEFT", frame, "TOPLEFT")

  local resetAllButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  resetAllButton:SetText("Reset All Save Data")
  resetAllButton:SetScript("OnClick", function()
    addon.StaticPopups:Show("ResetSaveData")
  end)
  resetAllButton:SetWidth(200)
  resetAllButton:SetPoint("TOPLEFT", resetFramesButton, "BOTTOMLEFT", 0, -8)
end