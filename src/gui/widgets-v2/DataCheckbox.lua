local _, addon = ...
local CreateFrame = addon.G.CreateFrame
local asserttype = addon.asserttype

local widget = addon:NewWidget("DataCheckbox")

local defaultOptions = {
  text = "",                -- [string] Text to display to the right of the checkbox
  spacing = 2,              -- [number] Spacing between the checkbox and its text

  autoLoad = true,          -- [boolean] If true, the widget will be refreshed immediately
  get = nil,                -- [function() -> boolean] Getter to load the value
  set = nil,                -- [function(boolean)] Setter to save the value
}

local methods = {
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
}

local scripts = {
  ["OnClick"] = function(self, mouseButton, isDown)
    self:SetValue(self:GetChecked())
  end,
  ["OnShow"] = function(self)
    self:Refresh()
  end,
}

function widget:Create(frameName, parent, options)
  options = addon:MergeOptionsTable(defaultOptions, options)
  asserttype(options.get, "function", "options.get", "DataCheckbox:Create")
  asserttype(options.set, "function", "options.set", "DataCheckbox:Create")

  local button = CreateFrame("CheckButton", frameName, parent, "UICheckButtonTemplate")
  button:SetText(options.text)
  button:SetPushedTextOffset(0, 0)
  button:SetNormalFontObject("GameFontNormal")
  button:SetDisabledFontObject("GameFontDisable")

  local fontString = button:GetFontString()
  fontString:ClearAllPoints()
  fontString:SetPoint("LEFT", button, "RIGHT", options.spacing, 0)

  button._options = options

  addon:ApplyMethods(button, methods)
  addon:ApplyScripts(button, scripts)

  if options.autoLoad then
    button:Refresh()
  end

  return button
end