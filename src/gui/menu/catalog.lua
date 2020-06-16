local _, addon = ...

local menu = addon.MainMenu:NewMenuScreen("catalog")

function menu:Create(frame)
  local label = frame:CreateFontString(nil, "BACKGROUND", "GameFontNormalLarge")
  label:SetText("Feature coming soon!")
  label:SetPoint("CENTER", frame, "CENTER")
end