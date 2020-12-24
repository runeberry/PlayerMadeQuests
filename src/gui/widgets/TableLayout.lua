local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local widget = addon.CustomWidgets:NewWidget("TableLayout")

local defaultOptions = {
  margins = 0, -- Format: number or { l, r, t, b }
  spacing = 0, -- Format: number or { x, y }
  -- Unless overridden, a table will automatically resize to fit its content
  width = "auto",
  height = "auto",
}

local defaultRowOptions = {
  -- Overrides table-level width/height options, but can be overridden by row-specific options
  width = "auto",
  height = "auto",
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
  end,
  ["GetFrame"] = function(self, index)
    local frame = self._frames[index]
    assert(frame, "GetFrame: no frame at index: "..tostring(index))
    return frame
  end,
  --- Resizes the row to fit its current content
  ["Refresh"] = function(self)
    local options = self._options

    local sx, sy = addon:UnpackXY(options.spacing)

    if options.width == "auto" then
      -- Set the row width to the combined width of all frames
      local width = 0
      for _, frame in ipairs(self._frames) do
        width = width + frame:GetWidth()
      end
      -- Account for horizontal spacing between frames
      width = width + sx
      self:SetWidth(width)
    elseif type(options.width) == "number" then
      -- Width can be set to a static numeric value
      self:SetWidth(options.width)
    end

    if options.height == "auto" then
      -- Set the row height to the height of the tallest frame
      local height = 0
      for _, frame in ipairs(self._frames) do
        height = math.max(height, frame:GetHeight())
      end
      self:SetHeight(height)
    elseif type(options.height) == "number" then
      -- Height can be set to a static numeric value
      self:SetHeight(options.height)
    end
  end
}

local methods = {
  ["AddRow"] = function(self, options)
    options = addon:MergeOptionsTable(self._options, defaultRowOptions, options)

    local row = CreateFrame("Frame", nil, self)
    local rowIndex = #self._rows+1
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

    row._options = options
    row._frames = {}
    row._table = self

    addon:ApplyMethods(row, rowMethods)

    return row
  end,
  ["GetRow"] = function(self, index)
    local row = self._rows[index]
    assert(row, "GetRow: no row at index "..tostring(index))
    return row
  end,
  --- Resizes the frame to fit its current content
  ["Refresh"] = function(self)
    local options = self._options

    -- Start by refreshing the size of all rows
    for _, row in ipairs(self._rows) do
      row:Refresh()
    end

    local ml, mr, mt, mb = addon:UnpackLRTB(options.margins)
    local sx, sy = addon:UnpackXY(options.spacing)

    if options.width == "auto" then
      -- Set the table width to the width of the widest row
      local width = 0
      for _, row in ipairs(self._rows) do
        width = math.max(width, row:GetWidth())
      end
      -- Account for left/right margins
      width = width + ml + mr
      self:SetWidth(width)
    elseif type(options.width) == "number" then
      -- Width can be set to a static numeric value
      self:SetWidth(options.width)
    end

    if options.height == "auto" then
      -- Set the height to combined height of all rows
      local height = 0
      for _, row in ipairs(self._rows) do
        height = height + row:GetHeight()
      end
      -- Account for row spacing and top/bottom margins
      height = height + mt + mb + (math.max(0, #self._rows-1) * sy)
      self:SetHeight(height)
    elseif type(options.height) == "number" then
      -- Height can be set to a static numeric value
      self:SetHeight(options.height)
    end
  end,
}

function widget:Create(parent, options)
  options = addon:MergeOptionsTable(defaultOptions, options)

  local frame = CreateFrame("Frame", nil, parent)

  frame._options = options
  frame._rows = {}

  addon:ApplyMethods(frame, methods)

  return frame
end