local _, addon = ...
local CreateFrame, UIParent = addon.G.CreateFrame, addon.G.UIParent
local strsplit, strjoin = addon.G.strsplit, addon.G.strjoin

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
  ["default-centered"] = {
    inheritsFrom = "GameFontHighlightSmall",
    justifyH = "CENTER",
    spacing = 2,
  },
  ["highlight"] = {
    inheritsFrom = "GameFontNormalSmall",
    justifyH = "LEFT",
    spacing = 2,
  },
  ["highlight-centered"] = {
    inheritsFrom = "GameFontNormalSmall",
    justifyH = "CENTER",
    spacing = 2,
  },
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

-- Pulled from AceGUI-Window
function addon:SetBorderBoxTexture(frame)
  local dialogbg = frame:CreateTexture(nil, "BACKGROUND")
  dialogbg:SetTexture(137056) -- Interface\\Tooltips\\UI-Tooltip-Background
  dialogbg:SetPoint("TOPLEFT", 8, -24)
  dialogbg:SetPoint("BOTTOMRIGHT", -6, 8)
  dialogbg:SetVertexColor(0, 0, 0, .75)

  local topleft = frame:CreateTexture(nil, "BORDER")
  topleft:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
  topleft:SetWidth(64)
  topleft:SetHeight(64)
  topleft:SetPoint("TOPLEFT")
  topleft:SetTexCoord(0.501953125, 0.625, 0, 1)

  local topright = frame:CreateTexture(nil, "BORDER")
  topright:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
  topright:SetWidth(64)
  topright:SetHeight(64)
  topright:SetPoint("TOPRIGHT")
  topright:SetTexCoord(0.625, 0.75, 0, 1)

  local top = frame:CreateTexture(nil, "BORDER")
  top:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
  top:SetHeight(64)
  top:SetPoint("TOPLEFT", topleft, "TOPRIGHT")
  top:SetPoint("TOPRIGHT", topright, "TOPLEFT")
  top:SetTexCoord(0.25, 0.369140625, 0, 1)

  local bottomleft = frame:CreateTexture(nil, "BORDER")
  bottomleft:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
  bottomleft:SetWidth(64)
  bottomleft:SetHeight(64)
  bottomleft:SetPoint("BOTTOMLEFT")
  bottomleft:SetTexCoord(0.751953125, 0.875, 0, 1)

  local bottomright = frame:CreateTexture(nil, "BORDER")
  bottomright:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
  bottomright:SetWidth(64)
  bottomright:SetHeight(64)
  bottomright:SetPoint("BOTTOMRIGHT")
  bottomright:SetTexCoord(0.875, 1, 0, 1)

  local bottom = frame:CreateTexture(nil, "BORDER")
  bottom:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
  bottom:SetHeight(64)
  bottom:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMRIGHT")
  bottom:SetPoint("BOTTOMRIGHT", bottomright, "BOTTOMLEFT")
  bottom:SetTexCoord(0.376953125, 0.498046875, 0, 1)

  local left = frame:CreateTexture(nil, "BORDER")
  left:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
  left:SetWidth(64)
  left:SetPoint("TOPLEFT", topleft, "BOTTOMLEFT")
  left:SetPoint("BOTTOMLEFT", bottomleft, "TOPLEFT")
  left:SetTexCoord(0.001953125, 0.125, 0, 1)

  local right = frame:CreateTexture(nil, "BORDER")
  right:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
  right:SetWidth(64)
  right:SetPoint("TOPRIGHT", topright, "BOTTOMRIGHT")
  right:SetPoint("BOTTOMRIGHT", bottomright, "TOPRIGHT")
  right:SetTexCoord(0.1171875, 0.2421875, 0, 1)

  return frame
end