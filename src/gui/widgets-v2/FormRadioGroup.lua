local _, addon = ...
local assertf = addon.assertf
local unpack = addon.G.unpack

local template = addon:NewFrame("FormRadioGroup", "FlowLayout")
template:AddMixin("FormField")

template:SetDefaultOptions({
  labels = {},              -- [string] Text to display to the right of the checkbox

  margin = 0,                 -- [LRTB] Space between buttons and edge of containing group
  padding = { 8, 8, 0, 0 },   -- [LRTB] Space between the text inside the button and the edge of the button
  spacing = 6,                -- [number] Space between buttons

  anchor = "LEFT",            -- [string] Side anchor where the buttons will start growing from
})

local function validateButtonIndex(group, index)
  assertf(type(index) == "number" and index > 0 and index <= #group._buttons,
    "%s is not a valid tab index", tostring(index))
  return index
end

local function addButton(group, label)
  local groupOptions = group:GetOptions()
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

  group:AddContent(button, { inline = true })

  group._buttons[index] = button
end

template:AddMethods({
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
  ["OnRefresh"] = function(self)
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
  ["OnFormValueChange"] = function(self, value, isUserInput)
    self:Refresh()
  end,
  ["OnLabelChange"] = function(self)

  end,
  ["OnShow"] = function(self)
    self:Refresh()
  end,
})

function template:Create(frame, options)
  addon:ValidateSide(options.anchor)

  frame._buttons = {}

  for _, label in ipairs(options.labels) do
    addButton(frame, label)
  end
end