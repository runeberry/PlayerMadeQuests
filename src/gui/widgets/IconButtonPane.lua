local _, addon = ...
local CreateFrame, UIParent = addon.G.CreateFrame, addon.G.UIParent

local widget = addon.CustomWidgets:NewWidget("IconButtonPane")

local defaultAnchor = "TOP"
local defaultWidth, defaultHeight = 16, 16

local defaultButtonOptions = {
  anchor = nil, -- Depends on the orientation of the ButtonPane
  margin = 2,   -- The space between buttons and the edge of the pane
  spacing = 4,  -- The space between buttons
  width = nil,  -- Will be calculated by spacing & padding
  height = nil, -- Will be calculated by spacing & padding
}

local oppositeAnchor = {
  ["LEFT"] = "RIGHT",
  ["RIGHT"] = "LEFT",
  ["TOP"] = "BOTTOM",
  ["BOTTOM"] = "TOP"
}

local offsetDirection = {
  ["LEFT"] = 1,
  ["RIGHT"] = -1,
  ["TOP"] = -1,
  ["BOTTOM"] = 1
}

local methods = {
  ["AddButton"] = function(self, options)
    assert(options, "AddButton options are required")
    options = addon:MergeTable(defaultButtonOptions, options)

    if not options.anchor then
      if self._isVertical then
        options.anchor = "TOP"
      else
        options.anchor = "LEFT"
      end
    end

    -- If height or width are not explicitly defined, then size the
    -- button to fill the pane with respect to its margin
    local defaultFillSize = self._size - (options.margin * 2)
    if self._isVertical then
      options.width = options.width or defaultFillSize
      options.height = options.height or defaultHeight
    else
      options.width = options.width or defaultWidth
      options.height = options.height or defaultFillSize
    end

    local ibutton = addon.CustomWidgets:CreateWidget("IconButton", self, options)
    ibutton._anchor = options.anchor

    -- This new button needs to be anchored relative to the previous button at this anchor
    local prevButton
    for _, b in pairs(self._buttons) do
      if b._anchor == options.anchor then
        prevButton = b
      end
    end

    local parent, pAnchor, offset
    if prevButton then
      parent = prevButton
      pAnchor = oppositeAnchor[options.anchor]
      offset = offsetDirection[options.anchor] * options.spacing * 2
    else
      parent = self
      pAnchor = options.anchor
      offset = offsetDirection[options.anchor] * options.margin * 2
    end

    local offx, offy
    if self._isVertical then
      offx = 0
      offy = offset
    else
      offx = offset
      offy = 0
    end

    ibutton:SetPoint(options.anchor, parent, pAnchor, offx, offy)

    self._buttons[#self._buttons+1] = ibutton
    return ibutton
  end,
}

function widget:Create(parent, anchor, size)
  parent = parent or UIParent
  anchor = anchor or defaultAnchor

  local frame = CreateFrame("Frame", nil, parent)
  frame._anchor = anchor
  frame._buttons = {}

  if anchor == "LEFT" or anchor == "RIGHT" then
    frame._isVertical = true
    frame._size = size or defaultWidth
    frame:SetWidth(frame._size)
  elseif anchor == "TOP" or anchor == "BOTTOM" then
    frame._isVertical = false
    frame._size = size or defaultHeight
    frame:SetHeight(frame._size)
  else
    error("Unrecognized anchor for IconButtonPane: "..tostring(anchor))
  end

  if anchor == "LEFT" then
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT")
    frame:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT")
  elseif anchor == "RIGHT" then
    frame:SetPoint("TOPRIGHT", parent, "TOPRIGHT")
    frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT")
  elseif anchor == "TOP" then
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT")
    frame:SetPoint("TOPRIGHT", parent, "TOPRIGHT")
  elseif anchor == "BOTTOM" then
    frame:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT")
    frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT")
  end

  for fname, fn in pairs(methods) do
    frame[fname] = fn
  end

  return frame
end