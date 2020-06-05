local _, addon = ...

local menu = addon.MainMenu:NewMenuScreen("settings")

function menu:Create(frame)
  local label = frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
  label:SetText("Settings")
end