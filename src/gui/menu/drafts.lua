local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local menu = addon.MainMenu:NewMenuScreen([[drafts]], "My Questography", true)

function menu:Create(parent)
  local frame = CreateFrame("Frame", nil, parent)
  frame:Hide()

  local label = frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
  label:SetText("My Questography")

  return frame
end
