local _, addon = ...
local asserttype, assertf = addon.asserttype, addon.assertf

local template = addon:NewFrame("DataTable")

template:RegisterCustomScriptEvent("OnHeaderClicked")     -- When any header Button is clicked
template:RegisterCustomScriptEvent("OnCellClicked")       -- When any non-header cell is clicked
template:RegisterCustomScriptEvent("OnSelectionChanged")  -- When the currently selected cell changes

local defaultOptions = {
  columns = nil,          -- [table] An array of column info objects
  rowHeight = 12,         -- [number] Height of each row
  tablePadding = 8,       -- [LRTB] Padding on each side of the whole table
  hoverColor = { 0.5, 0.5, 0.1, 0.5 },  -- [RGBA] Color when hovering over a table row
  selectColor = { 0.5, 0.5, 0.1, 1 },   -- [RGBA] Color when a table row is selected

  frameTemplate = "TooltipBorderedFrameTemplate",
  fontTemplate = "GameFontHighlightSmall",
  headerFontTemplate = "GameFontNormalSmall",

  get = nil,              -- [function() -> table] Get all rows to display in the table
  getItem = nil,          -- [function(row, index) -> any] Getter to convert a row into another object for GetSelectedItem
}

local defaultColumnOptions  = {
  text = nil,             -- [string] The text for
  width = { flex = 1 },
  justifyH = "LEFT",
  sortable = false,
}

local function forCell(dataTable, r, c, action)
  action(dataTable._cells[r][c])
end

local function forRowCells(dataTable, r, action)
  for c, tableCell in ipairs(dataTable._cells[r]) do
    action(tableCell, c)
  end
end

local function forAllCells(dataTable, action)
  for r, tableRows in ipairs(dataTable._cells) do
    for c, tableCell in ipairs(tableRows) do
      action(tableCell, r, c)
    end
  end
end

local function isCellSelected(dataTable, r, c)
  local selRow, selCol = dataTable:GetSelection()
  local scrollOffset = dataTable:GetScrollPosition() - 1

  if selRow and r and selRow == r + scrollOffset then
    -- This cell is in the selected row
    if not selCol then
      -- No col is specified, so the whole row is selected
      return true
    elseif selCol and selCol == c then
      -- This cell is also in the selected column
      return true
    end
  elseif selCol and selCol == c then
    -- This cell is in the selected column, but not the selected row
    if not selRow then
      -- No row is specified, so the whole column is selected
      return true
    end
  end

  return false
end

local tableCellMethods = {
  ["SetBackgroundColor"] = function(self, r, g, b, a)
    if type(r) == "table" then
      -- Can pass individual numbers or a whole rgba table
      r, g, b, a = addon:UnpackRGBA(r)
    end

    self._backgroundTexture:SetColorTexture(r, g, b, a)
  end,
  ["ClearBackgroundColor"] = function(self)
    self._backgroundTexture:SetColorTexture(0, 0, 0, 0)
  end,

  ["SetContent"] = function(self, text)
    if text == nil then
      self:ClearContent()
      return
    end

    self:SetText(tostring(text))
    self._hasContent = true
  end,
  ["ClearContent"] = function(self)
    self:SetText()
    self._hasContent = false
  end,
}

local tableCellScripts = {
  ["OnClick"] = function(self)
    if self._r == 0 then
      self._dataTable:FireCustomScriptEvent("OnHeaderClicked", self._c)
    elseif self._hasContent then
      self._dataTable:FireCustomScriptEvent("OnCellClicked", self._r, self._c)
    end
  end,
  ["OnEnter"] = function(self)
    if self._r == 0 then return end -- Don't highlight header cells
    if not self._hasContent then return end -- Don't highlight cells with no content
    if isCellSelected(self._dataTable, self._r, self._c) then return end -- Don't change highlight if the cell is selected

    local hoverColor = self._dataTable._options.hoverColor
    forRowCells(self._dataTable, self._r, function(cell, c)
      cell:SetBackgroundColor(hoverColor)
    end)
  end,
  ["OnLeave"] = function(self)
    if self._r == 0 then return end -- Don't highlight header cells
    if not self._hasContent then return end -- Don't highlight cells with no content
    if isCellSelected(self._dataTable, self._r, self._c) then return end -- Don't change highlight if the cell is selected

    forRowCells(self._dataTable, self._r, function(cell, c)
      cell:ClearBackgroundColor()
    end)
  end,
}

local function createTableCell(dataTable, r, c)
  local options = dataTable._options

  local name = string.format("%sCell_R%iC%i", dataTable:GetName(), r, c)
  local button = addon:CreateFrame("Button", name, dataTable)
  button:SetHeight(options.rowHeight)
  button:SetPushedTextOffset(0, 0)

  local fontTemplate = options.fontTemplate
  if r == 0 then fontTemplate = options.headerFontTemplate end
  local fontString = button:CreateFontString(name.."_FS", "BACKGROUND", fontTemplate)
  button:SetFontString(fontString)

  local justifyH = options.columns[c].justifyH
  if justifyH == "LEFT"  or justifyH == "RIGHT" then
    -- Setting justify alone doesn't seem to work in a Button. Re-anchor it.
    fontString:SetJustifyH(justifyH)
    fontString:ClearAllPoints()
    fontString:SetPoint(justifyH, button, justifyH)
  end

  local backgroundTexture = button:CreateTexture(name.."_TX", "ARTWORK")
  backgroundTexture:SetAllPoints(true)

  addon:ApplyMethods(button, tableCellMethods)
  addon:ApplyScripts(button, tableCellScripts)

  button._dataTable = dataTable
  button._backgroundTexture = backgroundTexture
  button._r = r
  button._c = c

  return button
end

local function initHeaders(dataTable)
  local columns = dataTable._options.columns
  local numCols = #columns
  local headerRow = dataTable._cells[0]

  -- Header can only be initialized once
  if headerRow then return end

  headerRow = {}
  dataTable._cells[0] = headerRow

  for c = 1, numCols do
    local headerCell = createTableCell(dataTable, 0, c)

    if c > 1 then
      -- Anchor to the cell in the previous column
      headerCell:SetPoint("TOPLEFT", headerRow[c-1], "TOPRIGHT")
    else
      -- Anchor the first column header to the corner of the header frame
      local padL, padR, padT, padB = addon:UnpackLRTB(dataTable._options.tablePadding)
      headerCell:SetPoint("TOPLEFT", dataTable._headerFrame, "TOPLEFT", padL, 0)
    end

    headerCell:SetText(columns[c].header)
    headerRow[c] = headerCell
  end
end

local function initCells(dataTable)
  local numRows = dataTable:GetNumVisibleRows()
  local numCols = #dataTable._options.columns
  local tableRows = dataTable._cells

  if #tableRows < numRows then
    for r = #tableRows + 1, numRows do
      tableRows[r] = {}
    end
  end

  for r, tableRow in ipairs(tableRows) do
    if #tableRow < numCols then
      for c = #tableRow + 1, numCols do

        local tableCell = createTableCell(dataTable, r, c)

        if c > 1 then
          -- Anchor to the cell in the previous column
          tableCell:SetPoint("TOPLEFT", tableRow[c-1], "TOPRIGHT")
        elseif r > 1 then
          -- Anchor to the cell in col 1 of the previous row
          tableCell:SetPoint("TOPLEFT", tableRows[r-1][1], "BOTTOMLEFT")
        else
          -- Anchor the first cell to the corner of the table frame
          local padL, padR, padT, padB = addon:UnpackLRTB(dataTable._options.tablePadding)
          tableCell:SetPoint("TOPLEFT", dataTable._tableFrame, "TOPLEFT", padL, -1*padT)
        end

        tableRow[c] = tableCell
      end
    end
  end
end

local function setSortColumnToDefault(dataTable)
  for c, column in ipairs(dataTable._options.columns) do
    if column.defaultSort then
      dataTable:SetSortColumn(c, column.defaultSort)
      break
    end
  end
end

template:AddMethods({
  --------------------------
  -- View refresh methods --
  --------------------------
  ["Refresh"] = function(self)
    self:RefreshData()
    self:RefreshDisplay()
  end,
  ["RefreshData"] = function(self)
    local data = self._options.get() or {}

    local sortCol, sortOrder = self:GetSortColumn()
    if sortCol then
      if sortOrder == "DESC" then
        table.sort(data, function(a, b) return a[sortCol] > b[sortCol] end)
      else
        table.sort(data, function(a, b) return a[sortCol] < b[sortCol] end)
      end
    end

    self._data = data
  end,
  ["RefreshDisplay"] = function(self)
    local options = self._options

    initHeaders(self)
    initCells(self)

    local flexParams = {}
    for i, column in ipairs(options.columns) do
      flexParams[i] = column.width
    end

    local padL, padR, padT, padB = addon:UnpackLRTB(self._options.tablePadding)
    local usableWidth = self._tableFrame:GetWidth() - padL - padR
    local widths = addon:CalculateFlex(usableWidth, flexParams)

    local visibleData = self:GetVisibleData()

    forRowCells(self, 0, function(cell, c) -- Header row
      cell:SetWidth(widths[c])
    end)
    forAllCells(self, function(cell, r, c)
      cell:SetWidth(widths[c])

      -- Set cell content from the dataset
      cell:ClearContent()
      if visibleData[r] then
        cell:SetContent(visibleData[r][c])
      end

      -- Highlight the cell if it's selected
      if isCellSelected(self, r, c) then
        cell:SetBackgroundColor(options.selectColor)
      else
        cell:ClearBackgroundColor()
      end
    end)
  end,

  ------------------
  -- Data methods --
  ------------------
  ["GetAllData"] = function(self)
    return self._data
  end,
  ["GetVisibleData"] = function(self)
    local data = self:GetAllData()
    local scrollOffset = self:GetScrollPosition() - 1
    local pageSize = self:GetNumVisibleRows()

    local results = {}
    for i = 1, pageSize do
      local row = data[i + scrollOffset]
      if row then
        results[#results+1] = row
      end
    end

    return results
  end,

  ----------------------------
  -- Cell selection methods --
  ----------------------------
  ["GetSelection"] = function(self)
    return self._selectedRow, self._selectedCol
  end,
  ["SetSelection"] = function(self, rowIndex, colIndex)
    local r1, c1 = self:GetSelection()
    if rowIndex == r1 and colIndex == c1 then
      -- Same selection, make no changes
      return
    end

    self._selectedRow = rowIndex
    self._selectedCol = colIndex

    self:RefreshDisplay()
    self:FireCustomScriptEvent("OnSelectionChanged", rowIndex, colIndex)
  end,
  ["ClearSelection"] = function(self)
    self:SetSelection(nil, nil)
  end,

  -----------------------------
  -- Scroll & paging methods --
  -----------------------------
  ["GetNumVisibleRows"] = function(self)
    local options = self._options

    -- Show however many rows it takes to fill out the parent frame
    local frameHeight = self._tableFrame:GetHeight()
    local numRows = math.floor(frameHeight / options.rowHeight) - 1 -- Leave off a row to account for header
    numRows = math.max(numRows, 1) -- Must try to display at least one row

    return numRows
  end,
  -- Guaranteed to always be a value from 1 - #rows
  ["GetScrollPosition"] = function(self)
    return self._scrollPos
  end,
  -- +1 to scroll down, -1 to scroll up
  ["ScrollByRow"] = function(self, numRows)
    asserttype(numRows, "number", "numRows", "DataTable:ScrollByRow")

    local scrollPos = self:GetScrollPosition()
    -- Don't try to scroll above the 1st row
    scrollPos = math.max(scrollPos + numRows, 1)
    self:ScrollToRow(scrollPos)
  end,
  -- +1 to scroll down, -1 to scroll up
  ["ScrollByPage"] = function(self, numPages)
    asserttype(numPages, "number", "numPages", "DataTable:ScrollByPage")

    local pageSize = self:GetNumVisibleRows()
    self:ScrollByRow(numPages * pageSize)
  end,
  ["ScrollToRow"] = function(self, rowIndex)
    -- Above the 1st row, don't try to scroll
    if not rowIndex or rowIndex < 1 then return end

    -- The farthest you can scroll down is "#rows - pageSize"
    local pageSize = self:GetNumVisibleRows()
    rowIndex = math.min(rowIndex, math.max(#self._data - pageSize, 1))

    -- Same scroll position, don't change anything
    if self._scrollPos == rowIndex then return end

    self._scrollPos = rowIndex
    self:RefreshDisplay()
  end,

  ---------------------------
  -- Sort & filter methods --
  ---------------------------
  ["GetSortColumn"] = function(self)
    return self._sortColIndex, self._sortColOrder
  end,
  -- order: "ASC" or "DESC"
  ["SetSortColumn"] = function(self, colIndex, order)
    asserttype(colIndex, "number", "colIndex", "DataTable:SetSortColumn")
    assertf(colIndex > 0 and colIndex <= #self._options.columns,
      "DataTable:SetSortColumn - colIndex must be 1 - %i", #self._options.columns)

    if order ~= "DESC" then
      -- All values other than "DESC" will default to "ASC"
      order = "ASC"
    end

    if self._sortColIndex == colIndex and self._sortColOrder == order then
      -- Same sort, make no changes
      return
    end

    self._sortColIndex = colIndex
    self._sortColOrder = order

    self:Refresh()
  end,
  ["ClearSortColumn"] = function(self)
    if not self._sortColIndex then return end -- No sort currently applied, make no changes

    self._sortColIndex = nil
    self._sortColOrder = nil

    -- Restore default column sort even if all sorts are cleared
    setSortColumnToDefault(self)

    self:Refresh()
  end,
})

template:AddScripts({
  ["OnMouseWheel"] = function(self, delta)
    -- Delta will either be +1 (scroll up) or -1 (scroll down)
    self:ScrollByRow(-1*delta)
  end,
  ["OnHeaderClicked"] = function(self, c)
    local colOptions = self._options.columns[c]

    if colOptions.sortable then
      local sortCol, sortOrder = self:GetSortColumn()
      if sortCol == c then
        if sortOrder == "ASC" then
          sortOrder = "DESC"
        else
          sortOrder = "ASC"
        end
      else
        sortOrder = "ASC"
      end

      self:SetSortColumn(c, sortOrder)
      addon.UILogger:Trace("Set DataTable sort: %s %s", tostring(c), tostring(sortOrder))
    end
  end,
  ["OnCellClicked"] = function(self, r, c)
    local selectedRow = self:GetSelection()
    local clickedRow = r + (self:GetScrollPosition() - 1)

    if selectedRow == clickedRow then
      -- Deselect a row when it's already selected and clicked again
      self:ClearSelection()
    else
      self:SetSelection(clickedRow)
    end
  end,
  ["OnSelectionChanged"] = function(self, r, c)
    addon.UILogger:Trace("Set DataTable selection: %s, %s", tostring(r), tostring(c))
  end,
})

function template:Create(frameName, parent, options)
  options = addon:MergeOptionsTable(defaultOptions, options)
  asserttype(options.columns, "table", "options.columns", "DataTable:Create")
  assert(options.columns[1], "DataTable: at least one column is required")
  asserttype(options.get, "function", "options.get", "DataTable:Create")

  local defaultSort
  for c, column in ipairs(options.columns) do
    local paramName = string.format("options.columns[%i]", c)
    asserttype(column, "table", paramName, "DataTable:Create")

    column = addon:MergeOptionsTable(defaultColumnOptions, column)
    options.columns[c] = column

    asserttype(column.header, "string", paramName..".header", "DataTable:Create")

    if column.defaultSort then
      if defaultSort then
        error("DataTable:Create - only one column may specify defaultSort")
      end
      asserttype(column.defaultSort, "string", paramName..".defaultSort", "DataTable:Create")
      defaultSort = c
    end
  end

  local dataTable = addon:CreateFrame("Frame", frameName, parent)
  dataTable:EnableMouse(true)

  local headerFrame = addon:CreateFrame("Frame", frameName.."Header", dataTable)
  headerFrame:SetHeight(options.rowHeight)
  headerFrame:SetPoint("TOPLEFT", dataTable, "TOPLEFT")
  headerFrame:SetPoint("TOPRIGHT", dataTable, "TOPRIGHT")

  local tableFrame = addon:CreateFrame("Frame", frameName.."Table", dataTable, options.frameTemplate)
  tableFrame:SetPoint("TOPLEFT", headerFrame, "BOTTOMLEFT")
  tableFrame:SetPoint("TOPRIGHT", headerFrame, "BOTTOMRIGHT")
  tableFrame:SetPoint("BOTTOMLEFT", dataTable, "BOTTOMLEFT")
  tableFrame:SetPoint("BOTTOMRIGHT", dataTable, "BOTTOMRIGHT")

  dataTable._headerFrame = headerFrame
  dataTable._tableFrame = tableFrame
  dataTable._options = options

  dataTable._scrollPos = 1
  dataTable._data = {}
  dataTable._cells = {}

  return dataTable
end

function template:AfterCreate(dataTable)
  setSortColumnToDefault(dataTable)
end