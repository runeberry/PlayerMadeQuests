local _, addon = ...
local CreateFrame = addon.G.CreateFrame
local asserttype = addon.asserttype
local Mixin, BackdropTemplateMixin = addon.G.Mixin, addon.G.BackdropTemplateMixin

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

--- As of TBC classic, frames must inherit from "BackdropTemplate" or use
--- the BackdropTemplateMixin in order to access these methods.
--- See here: https://github.com/Stanzilla/WoWUIBugs/wiki/9.0.1-Consolidated-UI-Changes#backdrop-system-changes
local function TryAddBackdropMixin(frame)
  -- Frame already has backdrop methods
  if frame.SetBackdrop then return true end

  -- This client does not have the mixin available
  if not BackdropTemplateMixin then return false end

  Mixin(frame, BackdropTemplateMixin)
  return true
end

function addon:ApplyBackgroundStyle(frame)
  if not TryAddBackdropMixin(frame) then return end

  frame:SetBackdrop(backdrop)
  frame:SetBackdropColor(0, 0, 0)
  frame:SetBackdropBorderColor(0.4, 0.4, 0.4)
end

function addon:CreateScrollFrame(parent)
  local sfid = addon:CreateGlobalName("ScrollFrame")
  local scrollFrame = CreateFrame("ScrollFrame", sfid, parent, "UIPanelScrollFrameTemplate")
  local scrollBar = _G[sfid.."ScrollBar"]
  local scrollBarFrame = CreateFrame("Frame", nil, parent)

  scrollBarFrame:SetWidth(scrollBar:GetWidth())

  if TryAddBackdropMixin(scrollBarFrame) then
    -- Scrollbar won't look right without this, but at least the addon won't crash
    scrollBarFrame:SetBackdrop(scrollBarBackdrop)
    scrollBarFrame:SetBackdropColor(0, 0, 0)
  end

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

--[[
  Schema: (all fields are optional and operate independently)
    width: number
    minWidth: number
    maxWidth: number
    height: number
    minHeight: number
    maxHeight: number
--]]
--- Resizes the frame to the provided boundaries
function addon:ResizeFrame(frame, options)
  asserttype(frame, "table", "frame", "ResizeFrame")
  asserttype(options, "table", "options", "ResizeFrame")

  local width, height = frame:GetWidth(), frame:GetHeight()

  if options.width then
    asserttype(options.width, "number", "options.width", "ResizeFrame")
    width = options.width
  end

  if options.minWidth then
    asserttype(options.minWidth, "number", "options.minWidth", "ResizeFrame")
    if width < options.minWidth then
      width = options.minWidth
    end
  end

  if options.maxWidth then
    asserttype(options.maxWidth, "number", "options.maxWidth", "ResizeFrame")
    if width > options.maxWidth then
      width = options.maxWidth
    end
  end

  if options.height then
    asserttype(options.height, "number", "options.height", "ResizeFrame")
    height = options.height
  end

  if options.minHeight then
    asserttype(options.minHeight, "number", "options.minHeight", "ResizeFrame")
    if height < options.minHeight then
      height = options.minHeight
    end
  end

  if options.maxHeight then
    asserttype(options.maxHeight, "number", "options.maxHeight", "ResizeFrame")
    if height > options.maxHeight then
      height = options.maxHeight
    end
  end

  frame:SetSize(width, height)
  -- addon.UILogger:Trace("ResizeFrame: %i x %i", width, height)
end