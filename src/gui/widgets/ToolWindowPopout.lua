-- Adapted from AceGUIContainer-Window.lua
local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local widget = addon.CustomWidgets:NewWidget("ToolWindowPopout")

local frameOptions = {
  style = "titlebar",
  styleOptions = {
    texture = 251966, -- Interface\\PaperDollInfoFrame\\UI-GearManager-Title-Background
    text = "ToolWindowPopout",
  },
  movable = true,
  resizable = true,
  saveOpenState = true,
  position = {
    p1 = "RIGHT",
    p2 = "RIGHT",
    x = -100,
    y = 0,
    w = 400,
    h = 200,
  },
}

local methods = {
  ["GetContentFrame"] = function(self)
    return self._content
  end,
  ["SetTitleText"] = function(self, title)
    self._title:SetTitleText(title)
  end,
}

function widget:Create(frameName, options)
  options = addon:MergeTable(frameOptions, options or {})
  local frame = addon.CustomWidgets:CreateWidget("PopoutFrame", frameName, options)
  frame:SetFrameStrata("HIGH")
  frame:SetMinResize(200,100)
  frame:SetToplevel(true)
  frame:OnClose(function()
    frame:SaveWindowState()
  end)

  local content = CreateFrame("Frame", nil, frame)
  content:SetPoint("TOPLEFT", frame._title, "BOTTOMLEFT", 13, -5)
  content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -9, 13)
  frame._content = content

  addon:SetBorderBoxTexture(frame)

  for fname, fn in pairs(methods) do
    frame[fname] = fn
  end

  return frame
end
