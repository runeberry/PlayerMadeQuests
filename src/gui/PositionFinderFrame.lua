local _, addon = ...
local Locations = addon.Locations

addon.PositionFinderFrame = nil -- Built at end of file

local locationRows

local frameOptions = {
  styleOptions = {
    text = "Location Finder"
  },
  resizable = {
    minWidth = 400,
    minHeight = 250,
  },
  position = {
    p1 = "RIGHT",
    p2 = "RIGHT",
    x = -100,
    y = 0,
    w = 250,
    h = 300,
    shown = true
  }
}

local options = {
  colInfo = {
    {
      name = "Name",
      pwidth = 0.4,
      align = "LEFT"
    },
    {
      name = "Zone",
      pwidth = 0.2,
      align = "RIGHT"
    },
    {
      name = "Subzone",
      pwidth = 0.2,
      align = "RIGHT"
    },
    {
      name = "Coords",
      pwidth = 0.2,
      align = "RIGHT"
    }
  },
  dataSource = function()
    locationRows = {}
    local locations = Locations:FindAll()
    table.sort(locations, function(a, b) return a.locationId < b.locationId end)
    for _, location in pairs(locations) do
      local coords = addon:PrettyCoords(location.x, location.y)
      local row = { location.name, location.zone, location.subZone, coords, location.locationId }
      table.insert(locationRows, row)
    end
    return locationRows
  end,
  buttons = {
    {
      text = "New",
      anchor = "TOP",
      enabled = "Always",
      handler = function()
        local location = addon:GetPlayerLocation()
        addon.StaticPopups:Show("NewLocation", location)
      end,
    },
    {
      text = "Update",
      anchor = "TOP",
      enabled = "Row",
      handler = function(location)
        addon.StaticPopups:Show("UpdateLocation", location)
      end,
    },
    {
      text = "Rename",
      anchor = "TOP",
      enabled = "Row",
      handler = function(location)
        addon.StaticPopups:Show("RenameLocation", location)
      end,
    },
    {
      text = "Delete",
      anchor = "TOP",
      enabled = "Row",
      handler = function(location)
        addon.StaticPopups:Show("DeleteLocation", location)
      end,
    },
    {
      text = "Delete All",
      anchor = "TOP",
      enabled = "Row",
      handler = function()
        addon.StaticPopups:Show("ResetLocations")
      end,
    },
  },
}

local function setLocationText()
  local location = addon:GetPlayerLocation()
  local text
  if location.subZone == "" then
    text = location.zone .." ("..string.format("%.2f", location.x).. ", ".. string.format("%.2f", location.y)..")"
  else
    text = location.subZone.. ", "..location.zone .." ("..string.format("%.2f", location.x).. ", ".. string.format("%.2f", location.y)..")"
  end
  return text
end

local function buildPositionFinderFrame()
  local frame = addon.CustomWidgets:CreateWidget("ToolWindowPopout", "LocationFinderFrame", frameOptions)
  local contentFrame = frame:GetContentFrame()
  local text = setLocationText()
  local playerLocationText = contentFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
  playerLocationText:SetText(text)
  playerLocationText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT")
  playerLocationText:SetHeight(30)
  local dtwb = addon.CustomWidgets:CreateWidget("DataTableWithButtons", contentFrame, options)
  dtwb:ClearAllPoints()
  dtwb:SetPoint("TOPLEFT", playerLocationText, "BOTTOMLEFT")
  dtwb:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", 0, 9)
  local dataTable = dtwb:GetDataTable()
  dataTable:SubscribeMethodToEvents("RefreshData", "LocationAdded", "LocationUpdated", "LocationDeleted", "LocationDataLoaded", "LocationDataReset")
  dataTable:SubscribeMethodToEvents("ClearSelection", "LocationDataLoaded", "LocationDeleted", "LocationDataReset")
  dataTable:RefreshData()
  dataTable:EnableUpdates(true)
  dataTable:OnGetSelectedItem(function(row)
     return Locations:FindByID(row[5])
  end)
  addon:StartPollingLocation("location-frame")
  addon.AppEvents:Subscribe("PlayerLocationChanged", function(loc)
    text = setLocationText()
    playerLocationText:SetText(text)
  end)

  return frame
end

addon:OnSaveDataLoaded(function()
  if addon.AVOID_BUILDING_UI then return end
  addon.PositionFinderFrame = buildPositionFinderFrame()
end)