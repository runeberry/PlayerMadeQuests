local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local backdrop = {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], edgeSize = 16,
	insets = { left = 4, right = 3, top = 4, bottom = 3 }
}

local scrollBarBackdrop = {
  bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
  insets = { left = -1, right = 0, top = 4, bottom = 4 }
}

addon.DefaultArticleTextStyle = {
  ["header"] = {
    inheritsFrom = "GameFontNormalLarge",
    justifyH = "LEFT",
    spacing = 2,
  },
  ["page-header"] = {
    inheritsFrom = "GameFontNormalLarge",
    justifyH = "CENTER",
    spacing = 4,
  },
  ["default"] = {
    inheritsFrom = "GameFontHighlightSmall",
    justifyH = "LEFT",
    spacing = 2,
  },
  ["highlight"] = {
    inheritsFrom = "GameFontNormalSmall",
    justifyH = "LEFT",
    spacing = 2,
  }
}

function addon:ApplyBackgroundStyle(frame)
  frame:SetBackdrop(backdrop)
  frame:SetBackdropColor(0, 0, 0)
  frame:SetBackdropBorderColor(0.4, 0.4, 0.4)
end

function addon:CreateScrollFrame(parent)
  local sfid = addon:CreateID("PMQ_ScrollFrame%i")
  local scrollFrame = CreateFrame("ScrollFrame", sfid, parent, "UIPanelScrollFrameTemplate")
  local scrollBar = _G[sfid.."ScrollBar"]
  local scrollBarFrame = CreateFrame("Frame", nil, parent)

  scrollBarFrame:SetWidth(scrollBar:GetWidth())
  scrollBarFrame:SetBackdrop(scrollBarBackdrop)
  scrollBarFrame:SetBackdropColor(0, 0, 0)
  scrollBar:ClearAllPoints()
  scrollBar:SetPoint("TOPRIGHT", scrollBarFrame, "TOPRIGHT", 0, -19)
  scrollBar:SetPoint("BOTTOMRIGHT", scrollBarFrame, "BOTTOMRIGHT", 0, 18)

  return scrollFrame, scrollBarFrame
end