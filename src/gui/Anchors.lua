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

local nextClockwise = {
  LEFT = "TOPLEFT",
  RIGHT = "BOTTOMRIGHT",
  TOP = "TOPRIGHT",
  BOTTOM = "BOTTOMLEFT",
  TOPLEFT = "TOP",
  TOPRIGHT = "RIGHT",
  BOTTOMLEFT = "LEFT",
  BOTTOMRIGHT = "BOTTOM",
  CENTER = "CENTER",
}

local nextCounterClockwise = addon:InvertTable(nextClockwise)

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

local offsetLRTB = {
  LEFT =        { 1, 0, 0, 0 },
  RIGHT =       { 0, 1, 0, 0 },
  TOP =         { 0, 0, 1, 0 },
  BOTTOM =      { 0, 0, 0, 1 },
  TOPLEFT =     { 1, 0, 1, 0 },
  TOPRIGHT =    { 0, 1, 1, 0 },
  BOTTOMLEFT =  { 1, 0, 0, 1 },
  BOTTOMRIGHT = { 0, 1, 0, 1 },
  CENTER =      { 0, 0, 0, 0 },
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
--- @param anchor string the anchor to push away from
--- @param spacing number the magnitude to push away with (number of px)
function addon:GetOffsetsFromSpacing(anchor, spacing)
  local dirs = offsetDirection[anchor]
  return spacing*dirs[1], spacing*dirs[2]
end

--- Given a set of positive values for LRTB, gives the directionalized offets
--- to push away from the provided anchor.
--- @param anchor string the anchor to push away from
--- @param lrtb table (or number) that can be unpacked as LRTB values
function addon:GetOffsetsFromLRTB(anchor, lrtb)
  local opp = addon:GetOppositeAnchor(anchor) -- Use opposite to "push away"
  local dirs = offsetDirection[opp]
  local incl = offsetLRTB[anchor]
  local l, r, t, b = addon:UnpackLRTB(lrtb)
  local x, y = 0, 0

  -- After deciding which sides are "included" in this anchor
  --   : 0 or 1 of l/r will be > 0, never both
  --   : 0 or 1 of t/b will be > 0, never both
  l, r, t, b = l*incl[1], r*incl[2], t*incl[3], b*incl[4]

  if l > 0 then x = l else x = r end
  if t > 0 then y = t else y = b end

  return x*dirs[1], y*dirs[2]
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
  return sides[anchor][1], sides[anchor][2]
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
  return corners[anchor][1], corners[anchor][2]
end

-- I wrote this function then didn't need it, but I'm leaving it here for future use
-- This has not been tested
function addon:GetAdjacentAnchor(anchor, steps)
  addon:ValidateAnchor(anchor)
  if steps == nil then steps = 1 end

  local ccw = steps < 0
  if ccw then steps = steps*-1 end

  while steps > 0 do
    if ccw then
      anchor = nextCounterClockwise[anchor]
    else
      anchor = nextClockwise[anchor]
    end
    steps = steps - 1
  end

  return anchor
end