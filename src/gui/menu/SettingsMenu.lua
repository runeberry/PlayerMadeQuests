local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local menu = addon.MainMenu:NewMenuScreen("SettingsMenu")

function menu:Create(frame)
  local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  button:SetText("Reset All Save Data")
  button:SetScript("OnClick", function()
    addon.StaticPopups:Show("ResetSaveData")
  end)
  button:SetWidth(200)
  button:SetPoint("TOPLEFT", frame, "TOPLEFT")
end