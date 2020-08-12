local _, addon = ...
local AceGUI = addon.AceGUI
local QuestLog, QuestStatus, localizer = addon.QuestLog, addon.QuestStatus, addon.QuestScriptLocalizer
local CreateFrame = addon.G.CreateFrame

addon.PositionFinderFrame = nil -- Built at end of file

local frameOptions = {
  styleOptions = {
    text = "Location Finder"
  },
  position = {
    p1 = "RIGHT",
    p2 = "RIGHT",
    x = -100,
    y = 0,
    w = 250,
    h = 300,
    shown = true
  }
}


local function buildPositionFinderFrame()
  local frame = addon.CustomWidgets:CreateWidget("ToolWindowPopout", "LocationFinderFrame", frameOptions)
  frame:SetSize(400, 250)
  frame:SetMinResize(400, 250)
  local content = frame:GetContentFrame()
  local text = "PLAYER_POSITION"
  local playerLocationText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  playerLocationText:SetText(text)
  playerLocationText:SetPoint("TOPLEFT", content, "TOPLEFT")
  playerLocationText:SetHeight(30)

  addon:StartPollingLocation("location-frame")
  addon.AppEvents:Subscribe("PlayerLocationChanged", function(loc)
    local location = addon:GetPlayerLocation()
    if location.subZone == "" then
      text = location.zone .." ("..string.format("%.2f", location.x).. ", ".. string.format("%.2f", location.y)..")"
    else
      text = location.subZone.. ", "..location.zone .." ("..string.format("%.2f", location.x).. ", ".. string.format("%.2f", location.y)..")"
    end

    playerLocationText:SetText(text)
  end)

  return frame
end

addon.PositionFinderFrame = buildPositionFinderFrame()

  -- local button = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
  -- button:SetPoint("TOPLEFT", content, "TOPLEFT")
  -- button:SetText("Print Coordinates")
  -- button:SetWidth(135)
  -- button:SetScript("OnClick", function()
  --   addon.Logger:Warn("Yay button!")
  --   local location = addon:GetPlayerLocation()
  --   addon.Logger:Warn("Coordinates: %s, %s", string.format("%.2f", location.x), string.format("%.2f", location.y))
  -- end)