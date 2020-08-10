local _, addon = ...
local AceGUI = addon.AceGUI
local QuestLog, QuestStatus, localizer = addon.QuestLog, addon.QuestStatus, addon.QuestScriptLocalizer

addon.PositionFinderFrame = nil -- Built at end of file

local frameOptions = {
  styleOptions = {
    text = "PMQ Position Finder"
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
  local frame = addon.CustomWidgets:CreateWidget("ToolWindowPopout", "PositionFinderFrame", frameOptions)
  local content = frame:GetContentFrame()

  local scrollGroup = AceGUI:Create("SimpleGroup")
  scrollGroup:SetFullWidth(true)
  scrollGroup:SetFullHeight(true)
  scrollGroup:SetLayout("Fill")

  scrollGroup.frame:SetParent(content)
  scrollGroup.frame:SetAllPoints(true)

  local scroller = AceGUI:Create("ScrollFrame")
  scroller:SetLayout("Flow")
  scrollGroup:AddChild(scroller)

  local buttonGroup = AceGUI:Create("SimpleGroup")
  buttonGroup:SetFullWidth(true)
  scroller:AddChild(buttonGroup)

  local moreButton = AceGUI:Create("Button")
  moreButton:SetText("Print Coordinates")
  moreButton:SetWidth(135)
  moreButton:SetCallback("OnClick", function()
    addon.Logger:Warn("Yay button!")
    local GetPlayerMapPosition = addon.G.GetPlayerMapPosition
    local GetBestMapForUnit = addon.G.GetBestMapForUnit
    local map = GetBestMapForUnit("player")
    local x, y = 0, 0
    if map then
      local position = GetPlayerMapPosition(map, "player")
      x, y = position:GetXY()
      addon.Logger:Warn("Coordinates: %s, %s", string.format("%.2f", x * 100), string.format("%.2f", y * 100))

    end
  end)
  buttonGroup:AddChild(moreButton)
  return frame
end

addon.PositionFinderFrame = buildPositionFinderFrame()