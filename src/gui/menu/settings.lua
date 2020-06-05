local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local menu = addon.MainMenu:NewMenuScreen("settings")

function menu:Create(parent)
  local frame = CreateFrame("Frame", nil, parent)
  frame:Hide()

  local label = frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
  label:SetText("Settings")

  return frame
end