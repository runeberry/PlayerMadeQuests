local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local widget = addon.CustomWidgets:NewWidget("TableLayout")

--[[
  Resizing rules: (these were just random thoughts, they are not actually implemented)
    1. A TableLayout (+ margins) must not exceed the height or width of its parent container.
       RESOLVE: Shrink the TableLayout to fit inside the parent container.

    2. A Row must not exceed the height or width of the TableLayout (- margins).
       RESOLVE: Shrink the Row to fit inside the TableLayout.
    3. The sum of all Rows (+ spacing) must not exceed the height of the TableLayout (- margins).
       RESOLVE: Truncate overflow
          3.1. Set the height of all Rows to (minHeight). Remaining space (RS) = TableLayout height - (Row minHeight * #Rows) - (y-spacing * (#Rows - 1))
          3.2. Set the height of a Row to the height of its tallest Frame. RS = RS - Row height
          3.3. While RS > 0, repeat Step 3.2 with the next Row.

    4. The sum of all Frames in a Row (+ spacing) must not exceed the width of the TableLayout.
       RESOLVE: Truncate overflow
          4.1. Set the width of all Frames to (minWidth). Remaining space (RS) = TableLayout width - (Frame minWidth * #Frames) - (x-spacing * (#Frames - 1))
          4.2. Set the width of a Frame
--]]

local defaultOptions = {
  margins = 0,        -- number or { l, r, t, b }
  spacing = 0,        -- number or { x, y }
  width = "auto",     -- number or "auto" (width of widest row)
  height = "auto",    -- number or "auto" (height of all rows)
}

-- Overrides table-level width/height options, but can be overridden by row-specific options
local defaultRowOptions = {
  margins = nil,      -- inherit, N/A to rows
  spacing = nil,      -- inherit
  width = "auto",     -- number or "auto" (width of all items)
  height = "auto",    -- number or "auto" (height of tallest item)
}

local rowMethods = {
  ["AddFrame"] = function(self, frame)
    assert(frame ~= nil, "AddFrame: a frame must be provided")
    assert(type(frame) == "table", "AddFrame: frame must be a table, got type: "..tostring(type(frame)))

    local options = self._options

    frame:ClearAllPoints(true)
    frame:SetParent(self)
    local colIndex = #self._frames+1
    self._frames[colIndex] = frame

    -- Row grows from LEFT to RIGHT
    if colIndex == 1 then
      -- The first frame is anchored to the row itself
      -- Currently there's no additional padding on the row
      frame:SetPoint("TOPLEFT", self, "TOPLEFT")
      frame:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT")
    else
      -- Subsequent frames are anchored to the previous frame
      local prev = self._frames[colIndex-1]
      local x, y = addon:UnpackXY(options.spacing)
      frame:SetPoint("TOPLEFT", prev, "TOPRIGHT", x, 0)
      frame:SetPoint("BOTTOMLEFT", prev, "BOTTOMRIGHT", x, 0)
    end

    frame:Show()
  end,
  ["GetFrame"] = function(self, index)
    local frame = self._frames[index]
    assert(frame, "GetFrame: no frame at index: "..tostring(index))
    return frame
  end,
  ["ClearAllFrames"] = function(self)
    for _, frame in ipairs(self._frames) do
      frame:ClearAllPoints(true)
      frame:Hide()
    end
    self._frames = {}
  end,
  --- Resizes the row to fit its current content
  ["Refresh"] = function(self)

    local options = self._options

    local targetHeight

    if options.height == "auto" then
      -- Set the row height to the height of the tallest frame
      targetHeight = 0
      for _, frame in ipairs(self._frames) do
        targetHeight = math.max(targetHeight, frame:GetHeight())
      end
    elseif type(options.height) == "number" then
      -- Height can be set to a static numeric value
      targetHeight = options.height
    end

    local resizeOptions = {
      width = self._container:GetWidth(),
      height = targetHeight,
    }

    addon:ResizeFrame(self, resizeOptions)
  end
}

local rowFrameCache = {}
local function getOrCreateRowFrame(tableFrame, index)
  local rowName = string.format("%s_Row_%i", tableFrame:GetName(), index)
  local row = rowFrameCache[rowName]

  if not row then
    row = CreateFrame("Frame", rowName, tableFrame)

    addon:ApplyMethods(row, rowMethods)

    row._frames = {}
    row._table = tableFrame
    row._container = tableFrame._container

    rowFrameCache[rowName] = row
  end

  return row
end

local methods = {
  ["AddRow"] = function(self, options)
    options = addon:MergeOptionsTable(self._options, defaultRowOptions, options)

    local rowIndex = #self._rows+1
    local row = getOrCreateRowFrame(self, rowIndex)
    row:SetWidth(self:GetWidth()) -- Row always fills the width of its table
    row._options = options

    self._rows[rowIndex] = row

    -- Table grows from TOPLEFT to BOTTOMRIGHT
    if rowIndex == 1 then
      -- The first row is anchored to the table itself
      local l, r, t, b = addon:UnpackLRTB(options.margins)
      row:SetPoint("TOPLEFT", self, "TOPLEFT", l, -1*t)
      row:SetPoint("TOPRIGHT", self, "TOPRIGHT", -1*r, -1*t)
    else
      -- Subsequent rows are anchored to the previous row
      local prev = self._rows[rowIndex-1]
      local x, y = addon:UnpackXY(options.spacing)
      row:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -1*y)
      row:SetPoint("TOPRIGHT", prev, "BOTTOMRIGHT", 0, -1*y)
    end

    row:Show()
    return row
  end,
  ["GetRow"] = function(self, index)
    local row = self._rows[index]
    assert(row, "GetRow: no row at index "..tostring(index))
    return row
  end,
  ["ClearAllRows"] = function(self)
    for _, row in ipairs(self._rows) do
      row:ClearAllFrames()
      row:Refresh()
      row:ClearAllPoints(true)
      row:Hide()
    end
    self._rows = {}
  end,
  --- Resizes the frame to fit its current content
  ["Refresh"] = function(self)
    -- Start by refreshing the size of all rows
    for _, row in ipairs(self._rows) do
      row:Refresh()
    end

    local options = self._options
    local ml, mr, mt, mb = addon:UnpackLRTB(options.margins)
    local sx, sy = addon:UnpackXY(options.spacing)
    local targetWidth, targetHeight

    if options.width == "auto" then
      -- Set the table width to the width of the widest row
      targetWidth = 0
      for _, row in ipairs(self._rows) do
        targetWidth = math.max(targetWidth, row:GetWidth())
      end
      -- Account for left/right margins
      targetWidth = targetWidth + ml + mr
    elseif type(options.width) == "number" then
      -- Width can be set to a static numeric value
      targetWidth = options.width
    end

    if options.height == "auto" then
      -- Set the height to combined height of all rows
      targetHeight = 0
      for _, row in ipairs(self._rows) do
        targetHeight = targetHeight + row:GetHeight()
      end
      -- Account for row spacing and top/bottom margins
      targetHeight = targetHeight + mt + mb + (math.max(0, #self._rows-1) * sy)
    elseif type(options.height) == "number" then
      -- Height can be set to a static numeric value
      targetHeight = options.height
    end

    local resizeOptions = {
      width = targetWidth,
      height = targetHeight,
      maxWidth = self._container:GetWidth(),
      maxHeight = self._container:GetHeight(),
    }

    addon:ResizeFrame(self, resizeOptions)
  end,
}

function widget:Create(parent, options)
  options = addon:MergeOptionsTable(defaultOptions, options)

  local frame = CreateFrame("Frame", addon:CreateGlobalName("TableLayout_%i"), parent)

  frame._options = options
  frame._rows = {}
  frame._container = parent -- Dimensions of the layout will be bounded to this frame

  addon:ApplyMethods(frame, methods)

  return frame
end