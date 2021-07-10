local _, addon = ...
local asserttype = addon.asserttype

local template = addon:NewFrame("Label")
template:RegisterCustomScriptEvent("OnLabelChange")

template:SetDefaultOptions({
  label = "",                                     -- [string] The text of the label
  labelLayer = "BACKGROUND",                      -- [string] The drawing layer for the fontString
  labelFontTemplate = "GameFontNormal",           -- [string]
  labelClickable = false,                         -- [bool] Should the label have mouse input/scripts enabled?
})

local function setLabel(self, text)
  self._labelFontString:SetText(text)

  -- Resize label's frame to fit the text within it
  local width, height = self._labelFontString:GetStringWidth(), self._labelFontString:GetStringHeight()
  self:SetSize(width, height)
end

template:AddMethods({
  ["GetText"] = function(self)
    return self._labelFontString:GetText()
  end,
  ["SetText"] = function(self, text)
    asserttype(text, "string", "text", "SetLabelText")

    if text == self:GetText() then return end

    setLabel(self, text)
    self:FireCustomScriptEvent("OnLabelChange", text)
  end,
})

-- These scripts can't be applied by default since we don't know if
-- mouse scripts are enabled until Create is run.
local mouseEnabledScripts = {
  ["OnClick"] = function(self)

  end,
  ["OnEnter"] = function(self)

  end,
  ["OnLeave"] = function(self)

  end,
}

function template:Create(frame, options)
  if options.labelClickable then
    frame:EnableMouse(true)
    addon.ApplyScripts(frame, mouseEnabledScripts)
  end

  local fontString = frame:CreateFontString(nil, options.labelLayer, options.labelFontTemplate)
  fontString:SetPoint("TOPLEFT", frame)

  local _, fontHeight = fontString:GetFont()
  frame:SetHeight(fontHeight)

  frame._labelFontString = fontString

  setLabel(frame, options.label)
end