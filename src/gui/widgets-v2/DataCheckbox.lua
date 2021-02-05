local _, addon = ...
local CreateFrame = addon.G.CreateFrame
local asserttype = addon.asserttype

local widget = addon:NewWidget("DataCheckbox")

local defaultOptions = {
  text = "",                -- [string] Text to display to the right of the checkbox
  spacing = 2,              -- [number] Spacing between the checkbox and its text
  get = nil,                -- [function()] Getter to load the value
  set = nil,                -- [function(boolean)] Setter to save the value
}

local methods = {
  ["Refresh"] = function(self)
    local value = self._options.get() and true
    self:SetChecked(value)
  end,
}

local scripts = {
  ["OnClick"] = function(self, mouseButton, isDown)
    self._options.set(self:GetChecked())
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

  -- local fontString = button:CreateFontString(frameName.."_Label", "BACKGROUND", "GameFontNormal")
  local fontString = button:GetFontString()
  fontString:ClearAllPoints()
  fontString:SetPoint("LEFT", button, "RIGHT", options.spacing, 0)
  -- fontString:SetText(options.text)

  button._options = options
  -- button._fontString = fontString

  addon:ApplyMethods(button, methods)
  addon:ApplyScripts(button, scripts)

  return button
end