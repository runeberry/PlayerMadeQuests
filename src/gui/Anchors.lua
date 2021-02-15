local _, addon = ...

local anchors = {
  LEFT = "LEFT",
  RIGHT = "RIGHT",
  TOP = "TOP",
  BOTTOM = "BOTTOM",
  TOPLEFT = "TOPLEFT",
  TOPRIGHT = "TOPRIGHT",
  BOTTOMLEFT = "BOTTOMLEFT",
  BOTTOMRIGHT = "BOTTOMRIGHT",
  CENTER = "CENTER",
}
addon.Anchors = anchors

local opposite = {
  LEFT = "RIGHT",
  RIGHT = "LEFT",
  TOP = "BOTTOM",
  BOTTOM = "TOP",
  TOPLEFT = "BOTTOMRIGHT",
  TOPRIGHT = "BOTTOMLEFT",
  BOTTOMLEFT = "TOPRIGHT",
  BOTTOMRIGHT = "TOPLEFT",
  CENTER = nil,
}

local direction = {
  LEFT = 1,
  RIGHT = -1,
  TOP = -1,
  BOTTOM = 1,
}

local offsetDirection = {
  LEFT = { 1, 0 },
  RIGHT = { -1, 0 },
  TOP = { 0, -1 },
  BOTTOM = { 0, 1 },
  TOPLEFT = { 1, -1 },
  TOPRIGHT = { -1, -1 },
  BOTTOMLEFT = { 1, 1 },
  BOTTOMRIGHT = { 1, -1 },
  CENTER = { 0, 0 },
}

local sides = {
  TOPLEFT = { "TOP", "LEFT" },
  TOPRIGHT = { "TOP", "RIGHT" },
  BOTTOMLEFT = { "BOTTOM", "LEFT" },
  BOTTOMRIGHT = { "BOTTOM", "RIGHT" },
}

local corners = {
  LEFT = { "TOPLEFT", "BOTTOMLEFT" },
  RIGHT = { "TOPRIGHT", "BOTTOMRIGHT" },
  TOP = { "TOPLEFT", "TOPRIGHT" },
  BOTTOM = { "BOTTOMLEFT", "BOTTOMRIGHT" }
}

--- Ensures that the provided string is a known anchor value
--- @param anchor string the anchor to validate
function addon:ValidateAnchor(anchor)
  assert(type(anchor) == "string", "Anchor must be a string")
  assert(anchors[anchor], anchor.." is not a valid anchor value")
end

--- Ensures that the provided string is a side anchor (not a corner or center)
--- @param anchor string the anchor to validate
function addon:ValidateSide(anchor)
  assert(type(anchor) == "string", "Anchor must be a string")
  assert(corners[anchor], anchor.." is not a valid side anchor")
end

--- Ensures that the provided string is a corner anchor (not a side or center)
--- @param anchor string the anchor to validate
function addon:ValidateCorner(anchor)
  assert(type(anchor) == "string", "Anchor must be a string")
  assert(sides[anchor], anchor.." is not a valid corner anchor")
end

--- Returns a valid anchor value representing the opposite side/corner of the provided anchor
--- @param anchor string the anchor to get the opposite of
function addon:GetOppositeAnchor(anchor)
  addon:ValidateAnchor(anchor)
  assert(opposite[anchor], "Unable to determine opposite anchor for "..anchor)
  return opposite[anchor]
end

--- Returns a value of +1 or -1, indicating the
--- @param anchor string the anchor to get the direction of
--- @param opp boolean flag to return the direction opposite the provided anchor
function addon:GetOffsetDirection(anchor, opp)
  addon:ValidateSide(anchor)

  if opp then
    anchor = addon:GetOppositeAnchor(anchor)
  end

  assert(direction[anchor], "Unable to determine offset direction for anchor "..anchor)
  return direction[anchor]
end

--- Returns the x,y values needed to "push away" from the specified anchor.
--- @param anchor string the side to push away from
--- @param padding number the magnitude to push away with (number of px)
function addon:GetOffsetsFromPadding(anchor, padding)
  local opp = addon:GetOppositeAnchor(anchor) -- Use opposite to "push away"
  local offsets = offsetDirection[opp]

  return opp, offsets[1]*padding, offsets[2]*padding
end

--- Returns the two side anchors associated with a corner anchor
--- @param anchor string the corner anchor to get the sides for
--- @param opp boolean flag to return the sides opposite the provided corner
function addon:GetSidesFromCorner(anchor, opp)
  addon:ValidateCorner(anchor)

  if opp then
    anchor = addon:GetOppositeAnchor(anchor)
  end

  assert(sides[anchor], "Unable to determine sides for corner "..anchor)
  return sides[anchor]
end

--- Returns the two corner anchors associated with a side anchor
--- @param anchor string the side anchor to get the corners for
--- @param opp boolean flag to return the corners opposite the provided side
function addon:GetCornersFromSide(anchor, opp)
  addon:ValidateSide(anchor)

  if opp then
    anchor = addon:GetOppositeAnchor(anchor)
  end

  assert(corners[anchor], "Unable to determine corners for side "..anchor)
  return corners[anchor]
end