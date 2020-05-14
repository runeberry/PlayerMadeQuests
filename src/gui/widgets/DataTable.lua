local _, addon = ...
addon:traceFile("DataTable.lua")
local CreateFrame, LibScrollingTable = addon.G.CreateFrame, addon.LibScrollingTable

local widget = addon.CustomWidgets:NewWidget("DataTable")

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

function widget:Create(parent, colinfo, datasource, ...)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetAllPoints(true)

  local st = LibScrollingTable:CreateST(colinfo, nil, nil, nil, frame)
  st.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -12)
  st.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
  st:EnableSelection(true)

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

  return frame
end