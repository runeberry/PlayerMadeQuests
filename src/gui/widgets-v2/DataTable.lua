local _, addon = ...
local LibScrollingTable = addon.LibScrollingTable
local asserttype = addon.asserttype

local template = addon:NewFrame("DataTable")
template:RegisterCustomScriptEvent("OnRowSelectionChanged")

local flexLogEnabled = false -- Enable if troubleshooting flex sizing
local flexLogger

local defaultOptions = {
  colInfo = nil,          -- [table] Array of column info objects passed to LibScrollingTable
  sortCol = nil,          -- [number] Sort table data by this column by default
  rowHeight = 15,         -- [number] The height of each row in the table
  highlightColor = {      -- [rgba] The highlight color when a row is selected
    r = 0.8,
    g = 0.7,
    b = 0,
    a = 0.5
  },

  get = nil,              -- [function() -> table] Getter to load all values for the table
  getItem = nil,          -- [function(row, index) -> any] Getter to convert an ST row into another object for GetSelectedItem
}

local function flexLog(...)
  if not flexLogEnabled then return end
  flexLogger = flexLogger or addon.Logger:NewLogger("DataTableFlex")
  flexLogger:Debug(...)
end

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
  flexLog("Available flex space: %.2f", flexSpace)

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
      flexLog("Col #%i: %s < %.2f < %s", i, tostring(wi.min), width, tostring(wi.max))

      if recalc then
        -- This col's width had to be assigned outside of the standard flex algorithm because:
        -- * it was outside its min-max range, or
        -- * it was assigned an absolute (non-flex) width
        -- Rerun the calcs with this width already assigned (will be excluded from recalc)
        ci.width = width
        flexLog("Col #%i: assigned absolute width %.2f, recalculating...", i, width)
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
        flexLog("Col #%i: assigned flex width %.2f", i, preWidths[i])
        ci.width = preWidths[i]
      else
        flexLog("Failed to calculate flex width for column #%i", i)
        ci.width = 1
      end
    end
  end
end

local function initScrollingTable(dataTable)
  if dataTable._scrollingTable then return end -- Already initialized
  local options = dataTable._options

  setWidthInfo(options.colInfo)

  -- Show however many rows it takes to fill out the parent frame
  local frameHeight = dataTable:GetHeight()
  local numRows = math.floor(frameHeight / options.rowHeight) - 1 -- Leave off a row to account for header
  numRows = math.max(numRows, 1) -- Must try to display at least one row

  local st = LibScrollingTable:CreateST(options.colInfo, numRows, options.rowHeight, options.highlightColor, dataTable)
  st.frame:SetPoint("TOPLEFT", dataTable, "TOPLEFT", 0, -12)
  st.frame:SetPoint("BOTTOMRIGHT", dataTable, "BOTTOMRIGHT")
  st:EnableSelection(true)
  addon:ApplyBackgroundStyle(st.frame)

  -- In order to detect row selection, wrap the base SetSelected in this custom function
  local origSetSelection = st.SetSelection
  st.SetSelection = function(self, row)
    origSetSelection(self, row)
    dataTable:FireCustomScriptEvent("OnRowSelectionChanged")
  end

  dataTable._scrollingTable = st
end

template:AddMethods({
  ["Refresh"] = function(self)
    self:RefreshData()
    self:RefreshDisplay()
  end,
  ["RefreshData"] = function(self)
    initScrollingTable(self)

    local data = self._options.get() or {}

    local sortCol = self._options.sortCol
    if sortCol then
      table.sort(data, function(a, b) return a[sortCol] < b[sortCol] end)
    end

    self._scrollingTable:SetData(data, true) -- Only supporting minimal data format for now

    for _, filter in pairs(self._filters) do
      self._scrollingTable:SetFilter(filter)
    end
  end,
  ["RefreshDisplay"] = function(self)
    initScrollingTable(self)

    local frameWidth = self._scrollingTable.frame:GetWidth() - 35 -- approx. account for edge inset and scrollbar
    flexLog("Total width of DataTable: %.2f", frameWidth)

    -- Setup: Clear all width values
    for i, ci in ipairs(self._options.colInfo) do
      ci.width = nil
    end

    -- Calculate flex and absolute widths based on the available space
    calcFlexWidths(self._options.colInfo, frameWidth)

    -- Teardown: as a failsafe, assign any remaining columns a width of 1px
    for i, ci in ipairs(self._options.colInfo) do
      if not ci.width or ci.width < 1 then
        flexLog("!!! Unresolved width for column #%i", i)
        ci.width = 1
      end
    end

    -- Pass the updated colInfo down into the base library
    self._scrollingTable:SetDisplayCols(self._options.colInfo)
  end,

  ["GetSelectedIndex"] = function(self)
    if not self._scrollingTable then return end
    return self._scrollingTable:GetSelection()
  end,
  ["GetSelectedRow"] = function(self)
    local index = self:GetSelectedIndex()
    if not index then return end
    return self._scrollingTable:GetRow(index)
  end,
  ["GetSelectedItem"] = function(self)
    local row = self:GetSelectedRow()
    if not row then return end
    if self._options.getItem then
      local ok = addon:catch(function()
        row = self._options.getItem(row, self:GetSelectedIndex())
      end)
      if not ok then return end
    end
    return row
  end,
  ["ClearSelection"] = function(self)
    return self._scrollingTable:ClearSelection()
  end,

  ["AddFilter"] = function(self, fnFilter)
    self._filters[#self._filters+1] = fnFilter
  end,
  ["ClearFilters"] = function(self)
    self._filters = {}
  end,

  -- Run the specified method on this DataTable whenever these events occur
  -- The subscriptions will only be run if updates are enabled on this DataTable
  ["SubscribeMethodToEvents"] = function(self, methodName, ...)
    asserttype(methodName, "string", "methodName", "DataTable:SubscribeMethodToEvents")
    asserttype(self[methodName], "function", "DataTable[methodName]", "DataTable:SubscribeMethodToEvents")

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
    self._enableUpdates = flag and true
  end,
})

template:AddScripts({
  ["OnShow"] = function(self)
    self:EnableUpdates(true)
    self:RefreshDisplay()
  end,
  ["OnHide"] = function(self)
    self:EnableUpdates(false)
  end,
  ["OnSizeChanged"] = function(self)
    self:RefreshDisplay()
  end,
})

function template:Create(frameName, parent, options)
  options = addon:MergeOptionsTable(defaultOptions, options)
  asserttype(options.colInfo, "table", "options.colInfo", "DataTable:Create")
  asserttype(options.get, "function", "options.get", "DataTable:Create")

  local dataTable = addon:CreateFrame("Frame", frameName, parent)

  dataTable._options = options
  dataTable._enableUpdates = true
  dataTable._filters = {}
  dataTable._subscriptions = {}

  -- The table itself isn't created until Refresh() is called
  return dataTable
end