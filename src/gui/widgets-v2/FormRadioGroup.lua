local _, addon = ...
local asserttype, assertf = addon.asserttype, addon.assertf
local unpack = addon.G.unpack

local template = addon:NewFrame("FormRadioGroup")

local defaultOptions = {
  labels = {},              -- [string] Text to display to the right of the checkbox

  margin = 0,                 -- [LRTB] Space between buttons and edge of containing group
  padding = { 8, 8, 0, 0 },   -- [LRTB] Space between the text inside the button and the edge of the button
  spacing = 6,                -- [number] Space between buttons

  anchor = "LEFT",            -- [string] Side anchor where the buttons will start growing from

  autoLoad = true,          -- [boolean] If true, the widget will be refreshed immediately
}

local function validateButtonIndex(group, index)
  assertf(type(index) == "number" and index > 0 and index <= #group._buttons,
    "%s is not a valid tab index", tostring(index))
  return index
end

-- The group's container size does not currently encapsulate labels
-- It's simply the area spanning from the TOPLEFT of the first checkbox
-- to the BOTTOMRIGHT of the last checkbox
local function resizeGroup(group)
  local options = group._options
  local horizontal = options.anchor == "LEFT" or options.anchor == "RIGHT"
  local groupWidth, groupHeight = 0, 0

  for i, button in ipairs(group._buttons) do
    local buttonWidth, buttonHeight = button:GetSize()
    if horizontal then
      groupWidth = groupWidth + buttonWidth + options.spacing
      groupHeight = math.max(groupHeight, buttonHeight)
    else
      groupWidth = math.max(groupWidth, buttonWidth)
      groupHeight = groupHeight + buttonHeight + options.spacing
    end
  end

  group:SetSize(groupWidth, groupHeight)
end

local function addButton(group, label)
  local groupOptions = group._options
  local buttonOptions = {
    radio = true,
    label = label,
  }
  local index = #group._buttons+1

  local buttonName = string.format("%sButton%i", group:GetName(), index)
  local button = addon:CreateFrame("FormCheckbox", buttonName, group, buttonOptions)
  button:SetCustomScript("OnFormValueChange", function(self, checked, isUserInput)
    if not isUserInput then return end
    group:SetFormValue(index)
  end)

  if index == 1 then
    -- Anchor the first button to the containing group
    local corner1, corner2 = addon:GetCornersFromSide(groupOptions.anchor)
    local x1, y1 = addon:GetOffsetsFromLRTB(corner1, groupOptions.margin)
    local x2, y2 = addon:GetOffsetsFromLRTB(corner2, groupOptions.margin)

    button:SetPoint(corner1, group, corner1, x1, y1)
    -- button:SetPoint(corner2, group, corner2, x2, y2)
  else
    -- Anchor buttons after the first to the previous button in the group
    local prevButton = group._buttons[index-1]
    local c1, c2 = addon:GetCornersFromSide(groupOptions.anchor)
    local p1, p2 = addon:GetCornersFromSide(groupOptions.anchor, true)
    local sx, sy = addon:GetOffsetsFromSpacing(groupOptions.anchor, groupOptions.spacing)

    button:SetPoint(c1, prevButton, p1, sx, sy)
    -- button:SetPoint(c2, prevButton, p2, sx, sy)
  end

  group._buttons[index] = button
end

template:AddMethods({
  ["Refresh"] = function(self)
    local selectedIndex = self:GetFormValue()
    for i, checkbox in ipairs(self._buttons) do
      -- Ensure that only the checkbox at the selected index is checked
      local expected = i == selectedIndex
      local actual = checkbox:GetFormValue() and true

      if expected ~= actual then
        checkbox:SetFormValue(expected, false)
      end
    end
  end,
  ["GetButton"] = function(self, index)
    validateButtonIndex(self, index)

    return self._buttons[index]
  end,
  ["GetAllButtons"] = function(self)
    return unpack(self._buttons)
  end,
  ["GetSelectedButton"] = function(self)
    local index = self:GetFormValue()
    if not index then return end

    return self:GetButton(index)
  end,
})

template:AddScripts({
  ["OnFormValueChange"] = function(self, value, isUserInput)
    self:Refresh()
  end,
  ["OnShow"] = function(self)
    self:Refresh()
  end,
})

function template:Create(frameName, parent, options)
  options = addon:MergeOptionsTable(defaultOptions, options)
  addon:ValidateSide(options.anchor)
  assert(options.anchor ~= "RIGHT", "The RIGHT anchor is not yet supported")

  local group = addon:CreateFrame("Frame", frameName, parent)

  group._options = options
  group._buttons = {}

  addon:ApplyFormFieldMethods(group, template)

  for _, label in ipairs(options.labels) do
    addButton(group, label)
  end

  resizeGroup(group)

  return group
end

function template:AfterCreate(button)
  if button._options.autoLoad then
    button:Refresh()
  end
end