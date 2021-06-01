local _, addon = ...
local assertf = addon.assertf
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

local layoutAnchorOptions = {
  LEFT = {
    anchor = "TOPLEFT",
    inline = true,
  },
  RIGHT = {
    anchor = "TOPRIGHT",
    inline = true,
  },
  TOP = {
    anchor = "TOPLEFT",
    inline = false,
  },
  BOTTOM = {
    anchor = "BOTTOMLEFT",
    inline = false,
  }
}

local function validateButtonIndex(group, index)
  assertf(type(index) == "number" and index > 0 and index <= #group._buttons,
    "%s is not a valid tab index", tostring(index))
  return index
end

local function resizeGroup(group)
  group._layout:Refresh()
  local width, height = group._layout:GetSize()
  group:SetSize(width, height)
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

  local lao = layoutAnchorOptions[groupOptions.anchor]
  group._layout:AddContent(button, { inline = lao.inline })

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

  local group = addon:CreateFrame("Frame", frameName, parent)

  local lao = layoutAnchorOptions[options.anchor]
  local layoutOptions = {
    anchor = lao.anchor,
    margin = options.margin,
    spacing = options.spacing,
    autoLoad = false,
  }
  local layout = addon:CreateFrame("FlowLayout", frameName.."Layout", group, layoutOptions)
  layout:SetPoint(lao.anchor, group, lao.anchor)

  group._options = options
  group._layout = layout
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