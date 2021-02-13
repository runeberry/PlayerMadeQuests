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
    self:SetChecked(self:GetValue())
  end,
  ["GetValue"] = function(self)
    return self._options.get() and true -- coerce value to boolean
  end,
  ["SetValue"] = function(self, value)
    value = value and true -- coerce value to boolean
    self._options.set(value)
  end,
})

template:AddScripts({
  ["OnClick"] = function(self, mouseButton, isDown)
    self:SetValue(self:GetChecked())
  end,
  ["OnShow"] = function(self)
    self:Refresh()
  end,
})

function template:Create(frameName, parent, options)
  options = addon:MergeOptionsTable(defaultOptions, options)
  asserttype(options.get, "function", "options.get", "DataCheckbox:Create")
  asserttype(options.set, "function", "options.set", "DataCheckbox:Create")

  local button = addon:CreateFrame("CheckButton", frameName, parent, "UICheckButtonTemplate")
  button:SetText(options.label)
  button:SetPushedTextOffset(0, 0)
  button:SetNormalFontObject("GameFontNormal")
  button:SetDisabledFontObject("GameFontDisable")

  local fontString = button:GetFontString()
  fontString:ClearAllPoints()
  fontString:SetPoint("LEFT", button, "RIGHT", options.spacing, 0)

  button._options = options

  return button
end

function template:AfterCreate(button)
  if button._options.autoLoad then
    button:Refresh()
  end
end