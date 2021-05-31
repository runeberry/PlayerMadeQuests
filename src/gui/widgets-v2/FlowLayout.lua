local _, addon = ...
local assertframe = addon.assertframe

local template = addon:NewFrame("FlowLayout")

local defaultLayoutOptions = {
  margin = 0,                 -- [LRTB] Space between content items and edge of the layout
  -- padding = { 8, 8, 0, 0 },   -- [LRTB] Not used
  spacing = 6,                -- [number] Space between content items

  anchor = "TOPLEFT",         -- [string] Corner anchor where the layout will start growing from

  autoLoad = true,            -- [boolean] If true, the widget will be refreshed whenever its contents change
}

-- Not yet implemented
local defaultItemOptions = {
  inline = false,         -- [boolean] Should the field be added on the same line as the previous field?
}

-- Add to existing row:
--  content:SetPoint("ANCHOR", prevContent, ap.horiz["ANCHOR"])
-- Add to new row:
--  content:SetPoint("ANCHOR", prevContent, ap.vert["ANCHOR"])
local anchorPoints = {
  horiz = {
    TOPLEFT = "TOPRIGHT",
    TOPRIGHT = "TOPLEFT",
    BOTTOMLEFT = "BOTTOMRIGHT",
    BOTTOMRIGHT = "BOTTOMLEFT",
  },
  vert = {
    TOPLEFT = "BOTTOMLEFT",
    TOPRIGHT = "BOTTOMRIGHT",
    BOTTOMLEFT = "TOPLEFT",
    BOTTOMRIGHT = "TOPRIGHT",
  }
}

local function resize(layout)
  local options = layout._options

  local ml, mr, mt, mb = addon:UnpackLRTB(options.margin)
  local sl, sr, st, sb = addon:UnpackLRTB(options.spacing)
  local layoutWidth, layoutHeight = 0, 0

  for _, row in ipairs(layout._table) do
    local rowWidth, rowHeight = 0, 0
    for _, content in ipairs(row) do
      rowWidth = rowWidth + content:GetWidth() + sl + sr
      rowHeight = math.max(rowHeight, content:GetHeight())
    end
    layoutWidth = math.max(layoutWidth, rowWidth)
    layoutHeight = layoutHeight + rowHeight + st + sb
  end

  -- Account for outer margins in size
  layoutWidth = layoutWidth + ml + mr
  layoutHeight = layoutHeight + mt + mb

  layout:SetSize(layoutWidth, layoutHeight)
end

local function addContentToTable(layout, content, options)
  local lt = layout._table
  local layoutOptions = layout._options
  local anchor = layoutOptions.anchor
  local itemOptions = addon:MergeOptionsTable(defaultItemOptions, options)
  content:ClearAllPoints()

  if #lt == 0 then
    -- First content item, create a new row in the table and add the content
    lt[1] = { content }

    -- Anchor the content to the anchor corner of the layout itself
    local x, y = addon:GetOffsetsFromLRTB(anchor, layoutOptions.margin)
    content:SetPoint(anchor, layout, anchor, x, y)
  elseif itemOptions.inline then
    -- Append the content to the end of the last row in the table
    local row = lt[#lt]
    row[#row+1] = content

    -- Anchor the content horizontally to the previous item in the row
    local prevContent = row[#row-1]
    if not prevContent then
      addon.UILogger:Warn("Unable to anchor FlowLayout content (inline, Row %i, Col %i)", #lt, #row)
    else
      local x, y = addon:GetOffsetsFromSpacing(layoutOptions.anchor, layoutOptions.spacing)
      content:SetPoint(anchor, prevContent, anchorPoints.horiz[anchor], x, 0)
    end
  else
    -- Create a new row in the table and add the content
    local row = { content }
    lt[#lt+1] = row

    -- Anchor the content vertically to the first item in the previous row
    local prevContent = lt[#lt-1][1]
    if not prevContent then
      addon.UILogger:Warn("Unable to anchor FlowLayout content (newline, Row %i, Col %i)", #lt, #row)
    else
      local x, y = addon:GetOffsetsFromSpacing(layoutOptions.anchor, layoutOptions.spacing)
      content:SetPoint(anchor, prevContent, anchorPoints.vert[anchor], 0, y)
    end
  end
end

template:AddMethods({
  ["Refresh"] = function(self)
    resize(self)
  end,
  ["AddContent"] = function(self, content, options)
    assertframe(content, "content", "AddContent")

    addContentToTable(self, content, options)

    if self._options.autoLoad then
      self:Refresh()
    end
  end,
})

function template:Create(frameName, parent, options)
  options = addon:MergeOptionsTable(defaultLayoutOptions, options)
  addon:ValidateCorner(options.anchor)

  local layout = addon:CreateFrame("Frame", frameName, parent)

  layout._options = options
  layout._table = {}

  return layout
end