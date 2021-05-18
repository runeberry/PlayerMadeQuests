local _, addon = ...

local template = addon:NewFrame("FormCheckbox")

local defaultOptions = {
  label = "",               -- [string] Text to display to the right of the checkbox
  spacing = 2,              -- [number] Spacing between the checkbox and its text
  radio = false,            -- [boolean] Should the button look and act like a radio button?

  autoLoad = true,          -- [boolean] If true, the widget will be refreshed immediately
}

-- The size of the checkbox widget should also encapsulate its text
local function resize(checkbox)
  local options = checkbox._options
  local button = checkbox._button

  local buttonWidth, buttonHeight = button:GetSize()
  buttonWidth = buttonWidth + options.spacing + button:GetTextWidth()
  checkbox:SetSize(buttonWidth, buttonHeight)
end

local function onButtonClick(button, mouseButton, isDown)
  local checkbox = button._checkbox
  local prevChecked = checkbox:GetFormValue()
  local curChecked = button:GetChecked()

  if prevChecked and not curChecked and checkbox._options.radio then
    -- Clicking on a "checked" radio button should not "uncheck" the box
    button:SetChecked(true)
    return
  end

  checkbox:SetFormValue(curChecked)
end

template:AddMethods({
  ["Refresh"] = function(self)
    self._button:SetChecked(self:GetFormValue())
  end,
  ["SetLabel"] = function(self, label)
    self._button:SetText(label)
    resize(self)
  end,
})

template:AddScripts({
  ["OnClick"] = function(self, mouseButton, isDown)
    self._button:Click()
  end,
  ["OnEnter"] = function(self)
    -- todo: show highlight texture on hover
    -- self._button:SetHighlight(true)
  end,
  ["OnLeave"] = function(self)
    -- todo: show highlight texture on hover
    -- self._button:SetHighlight(false)
  end,
  ["OnEnable"] = function(self)
    self._button:Enable()
  end,
  ["OnDisable"] = function(self)
    self._button:Disable()
  end,
  ["OnFormValueChange"] = function(self, value, isUserInput)
    if isUserInput then return end

    self:Refresh()
  end,
  ["OnShow"] = function(self)
    self:Refresh()
  end,
})

function template:Create(frameName, parent, options)
  options = addon:MergeOptionsTable(defaultOptions, options)

  local checkbox = addon:CreateFrame("Button", frameName, parent)
  checkbox:EnableMouse()

  local templateName = "UICheckButtonTemplate"
  if options.radio then templateName = "UIRadioButtonTemplate" end

  local button = addon:CreateFrame("CheckButton", nil, checkbox, templateName)
  button:SetPoint("TOPLEFT", checkbox, "TOPLEFT")
  button:SetText(options.label)
  button:SetPushedTextOffset(0, 0)
  button:SetNormalFontObject("GameFontNormal")
  button:SetDisabledFontObject("GameFontDisable")
  button:SetScript("OnClick", onButtonClick)
  button._checkbox = checkbox

  local fontString = button:GetFontString()
  fontString:ClearAllPoints()
  fontString:SetPoint("LEFT", button, "RIGHT", options.spacing, 0)

  addon:ApplyFormFieldMethods(checkbox, template)

  checkbox._options = options
  checkbox._button = button

  resize(checkbox)

  return checkbox
end

function template:AfterCreate(checkbox)
  if checkbox._options.autoLoad then
    checkbox:Refresh()
  end
end