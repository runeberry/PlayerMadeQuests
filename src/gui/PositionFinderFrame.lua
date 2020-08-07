local _, addon = ...
local AceGUI = addon.AceGUI
local QuestLog, QuestStatus, localizer = addon.QuestLog, addon.QuestStatus, addon.QuestScriptLocalizer

addon.PositionFinderFrame = nil -- Built at end of file

local frameOptions = {
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
  return frame
end

addon.PositionFinderFrame = buildPositionFinderFrame()
