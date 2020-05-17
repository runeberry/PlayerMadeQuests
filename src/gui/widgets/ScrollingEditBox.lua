local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local widget = addon.CustomWidgets:NewWidget("ScrollingEditBox")

local backdrop = {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], edgeSize = 16,
	insets = { left = 4, right = 3, top = 4, bottom = 3 }
}

local scrollBarBackdrop = {
  bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
  insets = { left = -1, right = 0, top = 4, bottom = 4 }
}

function widget:Create(parent)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetAllPoints(true)

  local editBoxBorderFrame = CreateFrame("Frame", nil, frame)
  editBoxBorderFrame:SetBackdrop(backdrop)
  editBoxBorderFrame:SetBackdropColor(0, 0, 0)
  editBoxBorderFrame:SetBackdropBorderColor(0.4, 0.4, 0.4)
  editBoxBorderFrame:SetPoint("TOPLEFT", frame, "TOPLEFT")
  editBoxBorderFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")

  local sfid = addon:CreateID("PMQ_ScrollingEditBox_%i")
  local scrollFrame = CreateFrame("ScrollFrame", sfid, editBoxBorderFrame, "UIPanelScrollFrameTemplate")
  local scrollBar = _G[sfid.."ScrollBar"]
  local scrollBarWidth = scrollBar:GetWidth()
  local scrollBarFrame = CreateFrame("Frame", nil, frame)
  scrollBarFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
  scrollBarFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
  scrollBarFrame:SetWidth(scrollBarWidth)
  scrollBarFrame:SetBackdrop(scrollBarBackdrop)
  scrollBarFrame:SetBackdropColor(0, 0, 0)
  scrollBar:ClearAllPoints()
  scrollBar:SetPoint("TOPRIGHT", scrollBarFrame, "TOPRIGHT", 0, -19)
  scrollBar:SetPoint("BOTTOMRIGHT", scrollBarFrame, "BOTTOMRIGHT", 0, 18)

  scrollFrame:SetPoint("TOPLEFT", editBoxBorderFrame, "TOPLEFT", 8, -8)
  scrollFrame:SetPoint("BOTTOMLEFT", editBoxBorderFrame, "BOTTOMLEFT", -8, 8)
  scrollFrame:SetPoint("TOPRIGHT", editBoxBorderFrame, "TOPRIGHT", -1*scrollBarWidth, -8)
  scrollFrame:SetPoint("BOTTOMRIGHT", editBoxBorderFrame, "BOTTOMRIGHT", -1*scrollBarWidth, 8)

  editBoxBorderFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1*scrollBarWidth, 0)
  editBoxBorderFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1*scrollBarWidth, 0)

  local editBox = CreateFrame("EditBox", nil, scrollFrame)
  editBox:SetMultiLine(true)
  editBox:SetAutoFocus(false)
  editBox:SetFontObject("ChatFontNormal")
  editBox:SetWidth(scrollFrame:GetWidth())
  editBox:SetScript("OnEscapePressed", function()
    editBox:ClearFocus()
  end)

  scrollFrame:SetScrollChild(editBox)

  frame.editBox = editBox

  return frame
end