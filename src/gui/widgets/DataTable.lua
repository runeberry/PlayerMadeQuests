local _, addon = ...
local CreateFrame, LibScrollingTable = addon.G.CreateFrame, addon.LibScrollingTable

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
}

function widget:Create(parent, colinfo, datasource)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetAllPoints(true)

  -- Set column widths if not explicitly set in pixels
  local frameWidth = frame:GetWidth() - 35 -- approx. account for edge inset and scrollbar
  local remainingWidth, remainingCols = frameWidth, {}
  for _, ci in pairs(colinfo) do
    if ci.pwidth then
      -- pwidth: percent width of the parent frame
      ci.width = ci.pwidth * frameWidth
      remainingWidth = remainingWidth - ci.width
    elseif ci.width then
      remainingWidth = remainingWidth - ci.width
    else
      table.insert(remainingCols, ci)
    end
  end
  for _, ci in pairs(remainingCols) do
    -- any cols without a width set will equally share the remaining space
    ci.width = remainingWidth / #remainingCols
  end

  -- Show however many rows it takes to fill out the parent frame
  local frameHeight = frame:GetHeight()
  local numRows = math.floor(frameHeight / rowHeight) - 1 -- Leave off a row to account for header
  numRows = math.max(numRows, 1) -- Must try to display at least one row

  local st = LibScrollingTable:CreateST(colinfo, numRows, rowHeight, highlightColor, frame)
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

  frame._dataSource = datasource
  frame._enableUpdates = true
  frame._filters = {}
  frame._subscriptions = {}
  frame._scrollingTable = st

  for name, method in pairs(methods) do
    frame[name] = method
  end

  return frame
end