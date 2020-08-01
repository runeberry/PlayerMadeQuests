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

-- For some reason GetPoint() returns the wrong position unless you move the window
-- Still trying to figure this one out
local function isInaccuratePoint(p1, p2, x, y)
  return p1 == "CENTER" and p2 == "CENTER" and x == 0 and y == 0
end

function addon:SaveWindowPosition(frame, saveDataName, defaultPos)
  local p1, _, p2, x, y = frame:GetPoint()
  if isInaccuratePoint(p1, p2, x, y) and defaultPos then
    p1 = defaultPos.p1
    p2 = defaultPos.p2
    x = defaultPos.x
    y = defaultPos.y
  end
  local w, h = frame:GetSize()

  if not addon.PlayerSettings.FrameData then
    addon.PlayerSettings.FrameData = {}
  end

  addon.PlayerSettings.FrameData[saveDataName] = strjoin(",", p1, p2, x, y, w, h)
  addon.SaveData:Save("Settings", addon.PlayerSettings)
  addon.UILogger:Trace("Saved window position: %s %s (%.2f, %.2f) %ix%i", p1, p2, x, y, w, h)
end

function addon:LoadWindowPosition(frame, saveDataName, defaultPos)
  local pos
  local frameData = addon.PlayerSettings.FrameData
  if frameData and frameData[saveDataName] then
    local p1, p2, x, y, w, h = strsplit(",", frameData[saveDataName])
    pos = {
      p1 = p1,
      p2 = p2,
      x = x,
      y = y,
      w = w,
      h = h,
    }
  elseif defaultPos then
    pos = defaultPos
  else
    addon.UILogger:Trace("No saved position or default position available for frame.")
    return
  end

  frame:SetSize(pos.w, pos.h)
  frame:SetPoint(pos.p1, UIParent, pos.p2, pos.x, pos.y)
  addon.UILogger:Trace("Loaded window position: %s %s (%.2f, %.2f) %ix%i", pos.p1, pos.p2, pos.x, pos.y, pos.w, pos.h)
end