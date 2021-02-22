local _, addon = ...
local asserttype = addon.asserttype

local template = addon:NewFrame("DataCheckbox")

local defaultOptions = {
  label = "",               -- [string] Text to display to the right of the checkbox
  spacing = 2,              -- [number] Spacing between the checkbox and its text

  autoLoad = true,          -- [boolean] If true, the widget will be refreshed immediately
  get = nil,                -- [function() -> boolean] Getter to load the value
  set = nil,                -- [function(boolean)] Setter to save the value
}

template:AddMethods({
  ["Refresh"] = function(self)
    self:SetChecked(self:GetFormValue())
  end,
})

template:AddScripts({
  ["OnClick"] = function(self, mouseButton, isDown)
    self:SetFormValue(self:GetChecked())
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

  local button = addon:CreateFrame("CheckButton", frameName, parent, "UICheckButtonTemplate")
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