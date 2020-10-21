local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local widget = addon.CustomWidgets:NewWidget("FramePanel")

local defaultOptions = {
  anchor = "LEFT",
  margin = 0,
  padding = 0,
  spacing = 0,
}

local defaultFrameOptions = {
  opposite = false,
  size = 1, -- Make frame technically visible by default
}

--- Given this anchor point on the panel, position a new frame with the following values
local sideProperties = {
  ["LEFT"] = {
    prop = "l",
    oppositeAnchor = "RIGHT",
    corners = { "TOPLEFT", "BOTTOMLEFT" },
    isVertical = false,
    offsetDirection = 1,
  },
  ["RIGHT"] = {
    prop = "r",
    oppositeAnchor = "LEFT",
    corners = { "TOPRIGHT", "BOTTOMRIGHT" },
    isVertical = false,
    offsetDirection = -1,
  },
  ["TOP"] = {
    prop = "t",
    oppositeAnchor = "BOTTOM",
    corners = { "TOPLEFT", "TOPRIGHT" },
    isVertical = true,
    offsetDirection = -1,
  },
  ["BOTTOM"] = {
    prop = "b",
    oppositeAnchor = "TOP",
    corners = { "BOTTOMLEFT", "BOTTOMRIGHT" },
    isVertical = true,
    offsetDirection = 1,
  },
}

local cornerProperties = {
  ["TOPLEFT"] = {
    sides = { x = "LEFT", y = "TOP" },
  },
  ["TOPRIGHT"] = {
    sides = { x = "RIGHT", y = "TOP" },
  },
  ["BOTTOMLEFT"] = {
    sides = { x = "LEFT", y = "BOTTOM" },
  },
  ["BOTTOMRIGHT"] = {
    sides = { x = "RIGHT", y = "BOTTOM" },
  },
}

local function normalizeLRTB(val)
  if val == nil then
    val = 0
  end
  if type(val) == "number" then
    val = { l = val, r = val, t = val, b = val }
  end

  val.l = val.l or 0
  val.r = val.r or 0
  val.t = val.t or 0
  val.b = val.b or 0

  return val
end

local function getSidesFromCorner(corner)
  local sx, sy = cornerProperties[corner].sides.x, cornerProperties[corner].sides.y
  return sideProperties[sx], sideProperties[sy]
end

-- Not use MergeTable because it handles arrays by merging rather than overwriting
local function mergeDefaultOptions(options)
  if not options then
    options = addon:CopyTable(defaultOptions)
  else
    options.anchor = options.anchor or defaultOptions.anchor
    options.margin = options.margin or defaultOptions.margin
    options.padding = options.padding or defaultOptions.padding
    options.spacing = options.spacing or defaultOptions.spacing
  end

  options.margin = normalizeLRTB(options.margin)
  options.padding = normalizeLRTB(options.padding)

  return options
end

local methods = {
  ["AddFrame"] = function(self, frame, options)
    if options then
      options = addon:MergeTable(defaultFrameOptions, options)
    else
      options = defaultFrameOptions
    end

    local anchor = self._options.anchor
    if options.opposite then
      anchor = sideProperties[anchor].oppositeAnchor
    end

    -- Find the last frame anchored to this point on the panel
    local anchorFrame
    for _, f in ipairs(self._frames) do
      if f._anchor == anchor then
        anchorFrame = f
      end
    end

    -- By adding the frame to the panel, it becomes a child of the panel itself
    frame:ClearAllPoints()
    frame:SetParent(self)
    frame._anchor = anchor
    self._frames[#self._frames+1] = frame

    local ap = sideProperties[anchor]

    -- Use panel properties to calculate x,y offsets for positioning
    local margin = self._options.margin -- LRTB table
    local padding = self._options.padding -- LRTB table
    local spacing = self._options.spacing -- number

    local c1, p1, c1x, c1y
    local c2, p2, c2x, c2y

    if anchorFrame then
      -- addon.UILogger:Trace("Anchoring to existing frame")

      -- The provided frame will be anchored relative to the last frame added to this anchor point
      c1, c2 = ap.corners[1], ap.corners[2]
      local opp = sideProperties[ap.oppositeAnchor]
      p1, p2 = opp.corners[1], opp.corners[2]

      local c1sx, c1sy = getSidesFromCorner(c1)
      local c2sx, c2sy = getSidesFromCorner(c2)

      local xs, ys = 0, 0
      if ap.isVertical then
        ys = spacing
      else
        xs = spacing
      end

      -- The absolute offset is the new frame's padding + the panel's spacing
      c1x = c1sx.offsetDirection * (padding[c1sx.prop] + xs)
      c1y = c1sy.offsetDirection * (padding[c1sy.prop] + ys)
      c2x = c2sx.offsetDirection * (padding[c2sx.prop] + xs)
      c2y = c2sy.offsetDirection * (padding[c2sy.prop] + ys)
    else
      -- addon.UILogger:Trace("Adding first frame to anchor")

      -- There is no other frame to anchor to, so position this frame relative to the panel
      anchorFrame = self
      c1, c2 = ap.corners[1], ap.corners[2]
      p1, p2 = c1, c2

      local c1sx, c1sy = getSidesFromCorner(c1)
      local c2sx, c2sy = getSidesFromCorner(c2)

      -- The absolute offset is the margin + padding for the (x or y)-side of the corner
      c1x = c1sx.offsetDirection * (margin[c1sx.prop] + padding[c1sx.prop])
      c1y = c1sy.offsetDirection * (margin[c1sy.prop] + padding[c1sy.prop])
      c2x = c2sx.offsetDirection * (margin[c2sx.prop] + padding[c2sx.prop])
      c2y = c2sy.offsetDirection * (margin[c2sy.prop] + padding[c2sy.prop])
    end

    frame:SetPoint(c1, anchorFrame, p1, c1x, c1y)
    frame:SetPoint(c2, anchorFrame, p2, c2x, c2y)

    -- addon.UILogger:Trace("FramePoint1: %s %s %i %i", c1, p1, c1x, c1y)
    -- addon.UILogger:Trace("FramePoint2: %s %s %i %i", c2, p2, c2x, c2y)

    if options.size then
      if ap.isVertical then
        frame:SetHeight(options.size)
      else
        frame:SetWidth(options.size)
      end
    end
  end,
}

function widget:Create(parent, options)
  assert(type(parent) == "table", "A parent frame must be provided")
  options = mergeDefaultOptions(options)
  assert(sideProperties[options.anchor], tostring(options.anchor).." is not a valid anchor for FramePanel")

  local panel = CreateFrame("Frame", nil, parent)
  panel._options = options
  panel._frames = {}

  for fname, fn in pairs(methods) do
    panel[fname] = fn
  end

  return panel
end