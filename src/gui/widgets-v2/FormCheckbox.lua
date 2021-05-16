local _, addon = ...
local asserttype = addon.asserttype

local template = addon:NewFrame("FormCheckbox")

local defaultOptions = {
  label = "",               -- [string] Text to display to the right of the checkbox
  spacing = 2,              -- [number] Spacing between the checkbox and its text
  radio = false,            -- [boolean] Should the button look and act like a radio button?

  autoLoad = true,          -- [boolean] If true, the widget will be refreshed immediately
}

template:AddMethods({
  ["Refresh"] = function(self)
    self:SetChecked(self:GetFormValue())
  end,
})

template:AddScripts({
  ["OnClick"] = function(self, mouseButton, isDown)
    local prevChecked = self:GetFormValue()
    local curChecked = self:GetChecked()

    if prevChecked and not curChecked and self._options.radio then
      -- Clicking on a "checked" radio button should not "uncheck" the box
      self:SetChecked(true)
      return
    end

    self:SetFormValue(curChecked)
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

  local templateName = "UICheckButtonTemplate"
  if options.radio then templateName = "UIRadioButtonTemplate" end

  local button = addon:CreateFrame("CheckButton", frameName, parent, templateName)
  button:SetText(options.label)
  button:SetPushedTextOffset(0, 0)
  button:SetNormalFontObject("GameFontNormal")
  button:SetDisabledFontObject("GameFontDisable")

  local fontString = button:GetFontString()
  fontString:ClearAllPoints()
  fontString:SetPoint("LEFT", button, "RIGHT", options.spacing, 0)

  addon:ApplyFormFieldMethods(button, template)

  button._options = options

  return button
end

function template:AfterCreate(button)
  if button._options.autoLoad then
    button:Refresh()
  end
end