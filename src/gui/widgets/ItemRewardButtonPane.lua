local _, addon = ...
local CreateFrame = addon.G.CreateFrame
local Anchors = addon.Anchors

local widget = addon.CustomWidgets:NewWidget("ItemRewardButtonPane")

local itemRewardButtonOptions = {
  large = true
}

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

  table.insert(self._itemRewardButtons, irb)
  return irb
end

local methods = {
  -- Expects an array of "item" objects with the following properties
  -- itemId - string, required
  -- count - number, optional
  -- usable - boolean, optional
  ["SetItems"] = function(self, items)
    assert(type(items) == "table", "SetItems - an array of items is required")

    -- Hide all currently shown rewards
    for _, irb in ipairs(self._itemRewardButtons) do
      irb:Hide()
    end

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
    end
  end,
}

function widget:Create(parent)
  local frame = CreateFrame("Frame", nil, parent)

  for fname, fn in pairs(methods) do
    frame[fname] = fn
  end

  frame._itemRewardButtons = {}

  return frame
end