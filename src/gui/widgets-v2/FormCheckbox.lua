local _, addon = ...

local template = addon:NewFrame("FormCheckbox", "Button")
template:AddMixin("FormField")

template:SetDefaultOptions({
  labelAnchor = "RIGHT",
  radio = false,            -- [boolean] Should the button look and act like a radio button?
})

-- The size of the checkbox widget should also encapsulate its text
local function resize(checkbox)
  local formLabelWidth, _, formLabelOffsetX = checkbox:GetFormLabelDimensions()
  local button = checkbox._button

  local buttonWidth, buttonHeight = button:GetSize()
  buttonWidth = buttonWidth + formLabelWidth + formLabelOffsetX
  checkbox:SetSize(buttonWidth, buttonHeight)
end

local function onButtonClick(button, mouseButton, isDown)
  local checkbox = button._checkbox
  local options = checkbox:GetOptions()
  local prevChecked = checkbox:GetFormValue()
  local curChecked = button:GetChecked()

  if prevChecked and not curChecked and options.radio then
    -- Clicking on a "checked" radio button should not "uncheck" the box
    button:SetChecked(true)
    return
  end

  checkbox:SetFormValue(curChecked)
end

template:AddScripts({
  ["OnRefresh"] = function(self)
    self._button:SetChecked(self:GetFormValue())
  end,
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
  ["OnFormLabelChange"] = function(self)
    resize(self)
  end,
  ["OnShow"] = function(self)
    self:Refresh()
  end,
})

function template:Create(frame, options)
  frame:EnableMouse(true)

  local templateName = "UICheckButtonTemplate"
  if options.radio then templateName = "UIRadioButtonTemplate" end

  local button = addon:CreateFrame("CheckButton", nil, frame, templateName)
  button:SetPoint("TOPLEFT", frame, "TOPLEFT")
  button:SetScript("OnClick", onButtonClick)
  frame:SetFormLabelParent(button)

  frame._button = button
  button._checkbox = frame

  resize(frame)
end