local _, addon = ...
addon:traceFile("DataTable.lua")
local CreateFrame, LibScrollingTable = addon.G.CreateFrame, addon.LibScrollingTable

local widget = addon.CustomWidgets:NewWidget("DataTable")

local rowHeight = 15
local highlightColor = { r = 0.8, g = 0.7, b = 0, a = 0.5 }

local function wrapEventRefresh(dt)
  return function(...)
    if dt._enableUpdates then
      dt:RefreshData(...)
    end
  end
end

-- Must be called before any data will be shown
local function dt_RefreshData(self, ...)
  local data = self._dataSource(...) or {}
  self._scrollingTable:SetData(data, true) -- Only supporting minimal data format for now
  for _, filter in pairs(self._filters) do
    self._scrollingTable:SetFilter(filter)
  end
end

local function dt_ApplyFilter(self, fnFilter)
  table.insert(self._filters, fnFilter)
end

local function dt_ClearFilters(self)
  self._filters = {}
end

local function dt_SubscribeToEvents(self, ...)
  for _, appEvent in pairs({ ... }) do
    if self._subscriptions[appEvent] then
      error("DataTable is already subscribed to event: "..appEvent)
    end
    local subKey = addon.AppEvents:Subscribe(appEvent, wrapEventRefresh(self))
    self._subscriptions[appEvent] = subKey
  end
end

local function dt_EnableUpdates(self, flag)
  if flag == nil then flag = true end
  self._enableUpdates = flag
end

local function dt_UnsubscribeFromEvents(self, ...)
  for _, appEvent in pairs({ ... }) do
    local subKey = self._subscriptions[appEvent]
    if subKey then
      addon.AppEvents:Unsubscribe(appEvent, subKey)
      self._subscriptions[appEvent] = nil
    end
  end
end

local function dt_GetSelectedRow(self)
  local index = self._scrollingTable:GetSelection()
  if not index then
    return nil
  end
  return self._scrollingTable:GetRow(index)
end

local function dt_ClearSelection(self)
  return self._scrollingTable:ClearSelection()
end

local function dt_OnRowSelected(self, fn)
  self.onRowSelected = fn
end

function widget:Create(parent, colinfo, datasource, ...)
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
      frame.onRowSelected(frame:GetSelectedRow())
    end
  end

  frame._dataSource = datasource
  frame._enableUpdates = true
  frame._filters = {}
  frame._subscriptions = {}
  frame._scrollingTable = st

  frame.ApplyFilter = dt_ApplyFilter
  frame.ClearFilters = dt_ClearFilters
  frame.RefreshData = dt_RefreshData
  frame.SubscribeToEvents = dt_SubscribeToEvents
  frame.EnableUpdates = dt_EnableUpdates
  frame.UnsubscribeFromEvents = dt_UnsubscribeFromEvents
  frame.GetSelectedRow = dt_GetSelectedRow
  frame.ClearSelection = dt_ClearSelection
  frame.OnRowSelected = dt_OnRowSelected

  return frame
end