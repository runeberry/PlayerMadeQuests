local _, addon = ...

local menu = addon.MainMenu:NewMenuScreen("settings")

function menu:Create(frame)
  local label = frame:CreateFontString(nil, "BACKGROUND", "GameFontNormalLarge")
  label:SetText("Feature coming soon!")
  label:SetPoint("CENTER", frame, "CENTER")
end