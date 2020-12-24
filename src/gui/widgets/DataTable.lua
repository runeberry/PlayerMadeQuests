local _, addon = ...
local CreateFrame, LibScrollingTable = addon.G.CreateFrame, addon.LibScrollingTable
local flexLogger = addon.Logger:NewLogger("Flex")

local widget = addon.CustomWidgets:NewWidget("DataTable")

local rowHeight = 15
local highlightColor = { r = 0.8, g = 0.7, b = 0, a = 0.5 }

local function wrapEventSubscription(dt, methodName)
  return function(...)
    if dt._enableUpdates then
      dt[methodName](dt, ...)
    end
  end
end

-- Ensure each colInfo object has a valid _widthInfo property
local function setWidthInfo(colInfo)
  for i, ci in ipairs(colInfo) do
    if ci._widthInfo then
      -- noop
    elseif type(ci.width) == "table" then
      ci._widthInfo = ci.width
      ci.width = 1
    elseif type(ci.width) == "number" then
      ci._widthInfo = { px = ci.width }
      ci.width = 1
    else
      ci._widthInfo = { min = 50 }
      ci.width = 1
    end
  end
end

local function isBetween(val, min, max)
  min = min or 1
  max = max or 999999

  if val < min then
    return false, min
  elseif val > max then
    return false, max
  end

  return true, val
end

local function getBetween(val, min, max)
  local ok, val2 = isBetween(val, min, max)
  return val2
end

local function calcFlexRatios(colInfo)
  local flexSum = 0
  for i, ci in ipairs(colInfo) do
    local wi = ci._widthInfo
    if ci.width then
      -- Col is already sized, does not contributed to flex width
    elseif type(wi.flexSize) == "number" then
      flexSum = flexSum + wi.flexSize
    else
      wi.flexSize = 1
      flexSum = flexSum + wi.flexSize
    end
  end

  -- No flex containers to size, everything is already sized
  if flexSum == 0 then return end

  for i, ci in ipairs(colInfo) do
    local wi = ci._widthInfo
    if wi.flexSize then
      wi.flexRatio = wi.flexSize / flexSum
    end
  end
end

local function calcFlexWidths(colInfo, flexSpace)
  if #colInfo == 0 then return end
  local preWidths = {}
  flexLogger:Trace("Available flex space: %.2f", flexSpace)

  -- Ratios change based on how many columns are being considered for flex
  calcFlexRatios(colInfo)

  for i, ci in ipairs(colInfo) do
    if not ci.width then
      local wi = ci._widthInfo
      local recalc, width

      if wi.px then
        width = getBetween(wi.px, wi.min, wi.max)
        recalc = true -- Always recalc when an absolute width is assigned
      elseif wi.flexRatio then
        local flexWidth = wi.flexRatio * flexSpace
        recalc, width = isBetween(flexWidth, wi.min, wi.max)
        recalc = not recalc -- actually want to recalc if isBetween returns false
      end
      flexLogger:Trace("Col #%i: %s < %.2f < %s", i, tostring(wi.min), width, tostring(wi.max))

      if recalc then
        -- This col's width had to be assigned outside of the standard flex algorithm because:
        -- * it was outside its min-max range, or
        -- * it was assigned an absolute (non-flex) width
        -- Rerun the calcs with this width already assigned (will be excluded from recalc)
        ci.width = width
        flexLogger:Trace("Col #%i: assigned absolute width %.2f, recalculating...", i, width)
        calcFlexWidths(colInfo, flexSpace - width)
      else
        -- Don't assign width directly yet, in case we need to recalc based a min-max resize
        preWidths[i] = width
      end
    end
  end

  for i, ci in ipairs(colInfo) do
    -- For any cols that have not been given width
    -- (should happen at the innermost recursion of this fn)
    if not ci.width then
      if preWidths[i] then
        flexLogger:Trace("Col #%i: assigned flex width %.2f", i, preWidths[i])
        ci.width = preWidths[i]
      else
        flexLogger:Debug("Failed to calculate flex width for column #%i", i)
        ci.width = 1
      end
    end
  end
end

local methods = {
  -- Must be called before any data will be shown
  ["RefreshData"] = function(self, ...)
    local data = self._dataSource(...) or {}
    self._scrollingTable:SetData(data, true) -- Only supporting minimal data format for now
    for _, filter in pairs(self._filters) do
      self._scrollingTable:SetFilter(filter)
    end
  end,
  ["ApplyFilter"] = function(self, fnFilter)
    table.insert(self._filters, fnFilter)
  end,
  ["ClearFilters"] = function(self)
    self._filters = {}
  end,
  -- Run the specified method on this DataTable whenever these events occur
  -- The subscriptions will only be run if updates are enabled on this DataTable
  ["SubscribeMethodToEvents"] = function(self, methodName, ...)
    assert(type(methodName) == "string", "Failed to SubscribeToEvents: methodName is required")
    assert(type(self[methodName]) == "function", "Failed to SubscribeToEvents: "..methodName.." is not a known method of DataTable")

    local subs = self._subscriptions[methodName]
    if not subs then
      subs = {}
      self._subscriptions[methodName] = subs
    end

    -- Wrap the method call so that it only runs if updates are enabled
    local wrappedSubscription = wrapEventSubscription(self, methodName)

    for _, appEvent in pairs({ ... }) do
      if subs[appEvent] then
        -- DataTable is already subscribed to perform this method on this AppEvent
      else
        subs[appEvent] = addon.AppEvents:Subscribe(appEvent, wrappedSubscription)
      end
    end
  end,
  ["EnableUpdates"] = function(self, flag)
    if flag == nil then flag = true end
    self._enableUpdates = flag
  end,
  ["GetSelectedRow"] = function(self)
    local index = self._scrollingTable:GetSelection()
    if not index then
      return nil
    end
    return self._scrollingTable:GetRow(index)
  end,
  ["GetSelectedItem"] = function(self)
    local row = self:GetSelectedRow()
    if not row then return end
    if self.onGetSelectedItem then
      local ok = addon:catch(function()
        row = self.onGetSelectedItem(row)
      end)
      if not ok then return end
    end
    return row
  end,
  ["ClearSelection"] = function(self)
    return self._scrollingTable:ClearSelection()
  end,
  ["SetClearSelectionEvents"] = function(self, ...)
    for _, appEvent in pairs({ ... }) do

    end
  end,
  ["OnRowSelected"] = function(self, fn)
    self.onRowSelected = fn
  end,
  ["OnGetSelectedItem"] = function(self, fn)
    self.onGetSelectedItem = fn
  end,
  ["RefreshColumns"] = function(self)
    local frameWidth = self._scrollingTable.frame:GetWidth() - 35 -- approx. account for edge inset and scrollbar
    flexLogger:Trace("Total width of DataTable: %.2f", frameWidth)

    -- Setup: Clear all width values
    for i, ci in ipairs(self._colInfo) do
      ci.width = nil
    end

    -- Calculate flex and absolute widths based on the available space
    calcFlexWidths(self._colInfo, frameWidth)

    -- Teardown: as a failsafe, assign any remaining columns a width of 1px
    for i, ci in ipairs(self._colInfo) do
      if not ci.width or ci.width < 1 then
        flexLogger:Debug("Unresolved width for column #%i", i)
        ci.width = 1
      end
    end

    -- Pass the updated colInfo down into the base library
    self._scrollingTable:SetDisplayCols(self._colInfo)
  end,
}

function widget:Create(parent, colInfo, datasource)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetAllPoints(true)

  setWidthInfo(colInfo)

  -- Show however many rows it takes to fill out the parent frame
  local frameHeight = frame:GetHeight()
  local numRows = math.floor(frameHeight / rowHeight) - 1 -- Leave off a row to account for header
  numRows = math.max(numRows, 1) -- Must try to display at least one row

  local st = LibScrollingTable:CreateST(colInfo, numRows, rowHeight, highlightColor, frame)
  st.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -12)
  st.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
  st:EnableSelection(true)
  addon:ApplyBackgroundStyle(st.frame)

  -- In order to detect row selection, wrap the base SetSelected in this custom function
  local origSetSelection = st.SetSelection
  st.SetSelection = function(self, row)
    origSetSelection(self, row)
    if frame.onRowSelected then
      addon:catch(function()
        frame.onRowSelected(frame:GetSelectedRow())
      end)
    end
  end

  frame._colInfo = colInfo
  frame._dataSource = datasource
  frame._enableUpdates = true
  frame._filters = {}
  frame._subscriptions = {}
  frame._scrollingTable = st

  addon:ApplyMethods(frame, methods)

  local resize = function() frame:RefreshColumns() end
  frame:SetScript("OnShow", resize)
  frame:SetScript("OnSizeChanged", resize)
  resize()

  return frame
end