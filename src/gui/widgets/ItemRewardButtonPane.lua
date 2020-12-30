local _, addon = ...
local CreateFrame = addon.G.CreateFrame
local Anchors = addon.Anchors
local asserttype = addon.asserttype

local widget = addon.CustomWidgets:NewWidget("ItemRewardButtonPane")

local itemRewardButtonOptions = {
  large = true
}

local function buildSelectionHandler(self, index)
  return function(selection)
    if selection then
      -- An item was selected
      self:SetSelectedIndex(index)
    else
      -- An item was deselected
      self:ClearSelection()
    end
  end
end

local function createNextButton(self)
  local irb = addon.CustomWidgets:CreateWidget("ItemRewardButton", self, itemRewardButtonOptions)

  local irbIndex = #self._itemRewardButtons + 1

  if irbIndex == 1 then
    -- First button is anchored to the pane
    irb:SetPoint(Anchors.TOPLEFT, self, Anchors.TOPLEFT)
  elseif irbIndex % 2 == 0 then
    -- Even-indexed buttons are anchored next to the previous button
    local prevButton = self._itemRewardButtons[irbIndex - 1]
    irb:SetPoint(Anchors.TOPLEFT, prevButton, Anchors.TOPRIGHT)
  else
    -- Odd-indexed buttons start a new row
    local prevButton = self._itemRewardButtons[irbIndex - 2]
    irb:SetPoint(Anchors.TOPLEFT, prevButton, Anchors.BOTTOMLEFT)
  end

  if self._selectable then
    irb:EnableSelection(true)
  end
  irb:OnSetSelected(buildSelectionHandler(self, irbIndex))

  table.insert(self._itemRewardButtons, irb)
  return irb
end

local methods = {
  -- Expects an array of "item" objects with the following properties
  -- itemId - string, required
  -- count - number, optional
  -- usable - boolean, optional
  ["SetItems"] = function(self, items)
    -- Hide all currently shown rewards
    for _, irb in ipairs(self._itemRewardButtons) do
      irb:Hide()
    end

    -- No items are specified, simply hide all items and return
    if not items then return end

    assert(type(items) == "table", "SetItems - a table of items must be provided")

    local height = 0

    for i, item in ipairs(items) do
      local irb = self._itemRewardButtons[i]

      if not irb then
        irb = createNextButton(self)
      end

      irb:SetItem(item.itemId)

      if item.count then
        irb:SetItemCount(item.count)
      end

      if item.usable ~= nil then
        irb:SetItemUsable(item.usable)
      end

      if i % 2 ~= 0 then
        -- Accumulate total pane height for each new row that's created
        height = height + irb:GetHeight()
      end

      irb:Show()
    end

    self:SetHeight(height)
  end,

  --- Allows for the selection (highlight) of ONE item within the pane
  ["EnableSelection"] = function(self, flag)
    if flag == nil then flag = true end
    self._selectable = flag

    -- Update selection flag for already existing buttons
    for _, button in ipairs(self._itemRewardButtons) do
      button:EnableSelection(flag)
    end
  end,
  ["GetSelectedIndex"] = function(self)
    return self._selected
  end,
  ["GetSelectedButton"] = function(self)
    local index = self:GetSelectedIndex()
    if not index then return nil end

    return self._itemRewardButtons[index]
  end,
  ["GetSelectedItem"] = function(self)
    local button = self:GetSelectedButton()
    if not button then return nil end

    return button:GetItem()
  end,
  ["SetSelectedIndex"] = function(self, index)
    if self._selected == index then return end -- Index is already selected

    local button = self:GetSelectedButton()
    if button then
      button:SetSelected(false)
      self._selected = nil
    end

    -- Setting to nil index simply clears the selection
    if index ~= nil then
      asserttype(index, "number", "index", "SetSelectedIndex")

      button = self._itemRewardButtons[index]
      if button then
        button:SetSelected(true)
        self._selected = index
      end
    end

    if self._onSelectionChanged then
      self._onSelectionChanged(index)
    end
  end,
  ["ClearSelection"] = function(self)
    self:SetSelectedIndex()
  end,
  ["OnSelectionChanged"] = function(self, handler)
    asserttype(handler, "function", "handler", "OnSelectionChanged")
    self._onSelectionChanged = handler
  end,
}

function widget:Create(parent)
  local frame = CreateFrame("Frame", nil, parent)

  addon:ApplyMethods(frame, methods)

  frame._itemRewardButtons = {}

  return frame
end