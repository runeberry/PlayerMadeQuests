local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local menu = addon.MainMenu:NewMenuScreen([[demo]], "Demo Quests")

function menu:Create(parent)
  local frame = CreateFrame("Frame", nil, parent)
  frame:Hide()

  local label = frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
  label:SetText("Demo Quests")

  return frame
end
