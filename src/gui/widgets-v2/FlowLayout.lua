local _, addon = ...
local assertframe = addon.assertframe

local template = addon:NewFrame("FlowLayout")

template:SetDefaultOptions({
  margin = 0,                 -- [LRTB] Space between content items and edge of the layout
  -- padding = { 8, 8, 0, 0 },   -- [LRTB] Not used
  spacing = 6,                -- [XY] Space between content items

  anchor = "TOPLEFT",         -- [string] Corner anchor where the layout will start growing from
})

-- Not yet implemented
local defaultItemOptions = {
  inline = false,         -- [boolean] Should the field be added on the same line as the previous field?
}

-- lazy constants
local TL, TR, BL, BR = "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"
local L, R, T, B = "LEFT", "RIGHT", "TOP", "BOTTOM"

-- [1] content anchor, first item
-- [2] parent anchor, first item
-- [3] content anchor, inline item
-- [4] previous content anchor, inline item
-- [5] content anchor, newline item
-- [6] previous line content anchor, newline item
-- [7] inline directional anchor
-- [8] newline directional anchor
-- [9] isVertical
local anchorPoints = {
  TOPLEFT =     { TL, TL, TL, TR, TL, BL, L, T },
  TOPRIGHT =    { TR, TR, TR, TL, TR, BR, R, T },
  BOTTOMLEFT =  { BL, BL, BL, BR, BL, TL, L, B },
  BOTTOMRIGHT = { BR, BR, BR, BL, BR, TR, R, B },
  LEFT =        { TL, TL, TL, TR, TL, BL, L, T },
  RIGHT =       { TR, TR, TR, TL, TR, BR, R, T },
  TOP =         { TL, TL, TL, BL, TL, TR, T, L, true },
  BOTTOM =      { BL, BL, BL, TL, BL, BR, B, L, true },
}

local function anchorFirstItem(layout, content)
  local lt = layout._table
  local layoutOptions = layout:GetOptions()
  local anchors = anchorPoints[layoutOptions.anchor]

  -- First content item, create a new row in the table and add the content
  lt[1] = { content }

  -- Anchor the content to the layout itself
  local x, y = addon:GetOffsetsFromLRTB(anchors[1], layoutOptions.margin)
  content:SetPoint(anchors[1], layout, anchors[2], x, y)
end

local function anchorInlineItem(layout, content)
  local lt = layout._table
  local layoutOptions = layout:GetOptions()
  local anchors = anchorPoints[layoutOptions.anchor]

  -- Append the content to the end of the last line in the table
  local row = lt[#lt]
  row[#row+1] = content

  -- Anchor the content to the previous item in the row
  local prevContent = row[#row-1]
  if not prevContent then
    addon.UILogger:Warn("Unable to anchor FlowLayout content (inline, Row %i, Col %i)", #lt, #row)
    return
  end

  local x, y = addon:GetOffsetsFromSpacing(anchors[7], layoutOptions.spacing)
  content:SetPoint(anchors[3], prevContent, anchors[4], x, y)
end

local function anchorNewlineItem(layout, content)
  local lt = layout._table
  local layoutOptions = layout:GetOptions()
  local anchors = anchorPoints[layoutOptions.anchor]

  -- Create a new row in the table and add the content
  local row = { content }
  lt[#lt+1] = row

  -- Anchor the content to the first item in the previous row
  local prevContent = lt[#lt-1][1]
  if not prevContent then
    addon.UILogger:Warn("Unable to anchor FlowLayout content (newline, Row %i, Col %i)", #lt, #row)
    return
  end

  local x, y = addon:GetOffsetsFromSpacing(anchors[8], layoutOptions.spacing)
  content:SetPoint(anchors[5], prevContent, anchors[6], x, y)
end

local function addContentToTable(layout, content, options)
  local itemOptions = addon:MergeOptionsTable(defaultItemOptions, options)
  content:ClearAllPoints()

  if #layout._table == 0 then
    anchorFirstItem(layout, content)
  elseif itemOptions.inline then
    anchorInlineItem(layout, content)
  else
    anchorNewlineItem(layout, content)
  end
end

local function resizeHorizontal(layout)
  local options = layout:GetOptions()
  local sx, sy = addon:UnpackXY(options.spacing)
  local layoutWidth, layoutHeight = 0, 0

  for _, line in ipairs(layout._table) do
    local lineWidth, lineHeight = 0, 0
    for _, content in ipairs(line) do
      lineWidth = lineWidth + content:GetWidth() + sx
      lineHeight = math.max(lineHeight, content:GetHeight())
    end

    -- Subtract the spacing for the last item in the row, as spacing should only be between elements
    lineWidth = lineWidth - sx

    layoutWidth = math.max(layoutWidth, lineWidth)
    layoutHeight = layoutHeight + lineHeight + sy
  end

  -- Subtract the spacing for the last row, as spacing should only be between rows
  layoutHeight = layoutHeight - sy

  return layoutWidth, layoutHeight
end

local function resizeVertical(layout)
  local options = layout:GetOptions()
  local sx, sy = addon:UnpackXY(options.spacing)
  local layoutWidth, layoutHeight = 0, 0

  for _, line in ipairs(layout._table) do
    local lineWidth, lineHeight = 0, 0
    for _, content in ipairs(line) do
      lineWidth = math.max(lineWidth, content:GetWidth())
      lineHeight = lineHeight + content:GetHeight() + sy
    end

    -- Subtract the spacing for the last item in the column, as spacing should only be between elements
    lineHeight = lineHeight - sy

    layoutWidth = layoutWidth + lineWidth + sx
    layoutHeight = math.max(layoutHeight, lineHeight)
  end

  -- Subtract the spacing for the last column, as spacing should only be between columns
  layoutWidth = layoutWidth - sx

  return layoutWidth, layoutHeight
end

local function resize(layout)
  local options = layout:GetOptions()
  local isVertical = anchorPoints[options.anchor][9]

  local layoutWidth, layoutHeight

  if isVertical then
    layoutWidth, layoutHeight = resizeVertical(layout)
  else
    layoutWidth, layoutHeight = resizeHorizontal(layout)
  end

  -- Account for outer margins in size
  local ml, mr, mt, mb = addon:UnpackLRTB(options.margin)
  layoutWidth = layoutWidth + ml + mr
  layoutHeight = layoutHeight + mt + mb

  layout:SetSize(layoutWidth, layoutHeight)
end

template:AddMethods({
  ["AddContent"] = function(self, content, options)
    assertframe(content, "content", "AddContent")

    addContentToTable(self, content, options)

    if self:GetOptions().autoRefresh then
      self:Refresh()
    end
  end
})

template:AddScripts({
  ["AfterRefresh"] = function(self)
    resize(self)
  end,
})

function template:Create(frame, options)
  addon:ValidateAnchor(options.anchor)

  frame._table = {}
end