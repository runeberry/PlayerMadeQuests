local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local widget = addon.CustomWidgets:NewWidget("DataTableWithIcons")

local iconTableSpacing = 4

local function setButtonState(container, row)
  if not container._buttons then return end

  for _, button in ipairs(container._buttons) do
    local enabled = false
    if button.enabled == "Always" then
      -- Button is always enabled, whether or not a row is selected
      enabled = true
    elseif button.enabled == "Conditional" and button.condition then
      -- Button is only enabled under certain conditions
      enabled = button.condition()
    elseif button.enabled == "Row" and row then
      -- Button is only enabled when a row is selected
      enabled = true
      if button.condition then
        -- Button is only enabled for certain conditions per row
        enabled = button.condition(row)
      end
    end

    button.frame:SetEnabled(enabled)
  end
end

local methods = {
  ["GetDataTable"] = function(self)
    return self._dataTable
  end,
  ["OnRowSelected"] = function(self, fn)
    self._onRowSelected = fn
  end,
  ["RefreshButtonState"] = function(self)
    setButtonState(self, self._dataTable:GetSelectedItem())
  end
}

function widget:Create(frame, options)
  assert(options and options.dataSource, "Failed to create DataTableWithIcons: dataSource is required")
  assert(options.colInfo, "Failed to create DataTableWithIcons: colInfo is required")

  local container = CreateFrame("Frame", nil, frame)
  container:SetAllPoints(true)

  local buttonWidth = options.buttonWidth or 16
  local buttonPane = addon.CustomWidgets:CreateWidget("IconButtonPane", container, "TOP", buttonWidth)

  local tablePane = CreateFrame("Frame", nil, container)
  tablePane:SetPoint("TOPLEFT", buttonPane, "BOTTOMLEFT", 0, -1 * iconTableSpacing)
  tablePane:SetPoint("TOPRIGHT", buttonPane, "BOTTOMRIGHT", 0, -1 * iconTableSpacing)
  tablePane:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT")
  tablePane:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT")

  local dataTable = addon.CustomWidgets:CreateWidget("DataTable", tablePane, options.colInfo, options.dataSource)
  dataTable:OnRowSelected(function(row)
    setButtonState(container, dataTable:GetSelectedItem())
    if container._onRowSelected then
      container:_onRowSelected(row)
    end
  end)

  if options.buttons then
    for _, buttonInfo in ipairs(options.buttons) do
      -- Provide the currently selected item (if available) to each button handler
      buttonInfo.frame = buttonPane:AddButton(buttonInfo)
      buttonInfo.frame:OnClick(function()
        if not buttonInfo.handler then return end
        buttonInfo.handler(dataTable:GetSelectedItem(), dataTable)
      end)
    end
  end

  for fname, fn in pairs(methods) do
    container[fname] = fn
  end

  container._buttons = options.buttons
  container._buttonPane = buttonPane
  container._dataTable = dataTable

  -- On create, set all buttons to their "default" state (no row selected)
  setButtonState(container)

  return container
end