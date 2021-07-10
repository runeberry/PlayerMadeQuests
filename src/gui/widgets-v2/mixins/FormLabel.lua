local _, addon = ...
local asserttype, assertf, assertframe = addon.asserttype, addon.assertf, addon.assertframe

local template = addon:NewMixin("FormLabel")
template:RegisterCustomScriptEvent("OnLabelChange")

template:SetDefaultOptions({
  labelAnchor = "LEFT",        -- [string] The anchor of the parent frame to hook the fontString to

  -- Specify the following settings only if you want to override anchor-specific options
  labelOffsetX = nil,          -- [number]
  labelOffsetY = nil,          -- [number]
})

template:SetConditionalOptions("labelAnchor", {
  LEFT = {
    labelFontTemplate = "GameFontNormal",
    labelAnchorHook = "RIGHT",
    labelOffsetX = -2,
    labelOffsetY = 0,
  },
  RIGHT = {
    labelFontTemplate = "GameFontNormal",
    labelAnchorHook = "LEFT",
    labelOffsetX = 2,
    labelOffsetY = 0,
  },
  TOP = {
    labelFontTemplate = "GameFontNormalSmall",
    labelAnchorHook = "BOTTOM",
    labelOffsetX = 0,
    labelOffsetY = 2,
  },
  BOTTOM = {
    labelFontTemplate = "GameFontNormalSmall",
    labelAnchorHook = "TOP",
    labelOffsetX = 0,
    labelOffsetY = -2,
  },
  TOPLEFT = {
    labelFontTemplate = "GameFontNormalSmall",
    labelAnchorHook = "BOTTOMLEFT",
    labelOffsetX = 0,
    labelOffsetY = 2,
  },
  TOPRIGHT = {
    labelFontTemplate = "GameFontNormalSmall",
    labelAnchorHook = "BOTTOMRIGHT",
    labelOffsetX = 0,
    labelOffsetY = 2,
  },
  BOTTOMLEFT = {
    labelFontTemplate = "GameFontNormalSmall",
    labelAnchorHook = "TOPLEFT",
    labelOffsetX = 0,
    labelOffsetY = -2,
  },
  BOTTOMRIGHT = {
    labelFontTemplate = "GameFontNormalSmall",
    labelAnchorHook = "TOPRIGHT",
    labelOffsetX = 0,
    labelOffsetY = -2,
  },
  -- CENTER = nil, -- Not supported
})

local function setFormLabelParent(self, parentFrame)
  self._formLabelParent = parentFrame

  -- Refresh label position
  local options = self:GetOptions()
  local labelParent = self._formLabelParent or self
  self._formLabel:ClearAllPoints(true)
  self._formLabel:SetPoint(options.labelAnchorHook, labelParent, options.labelAnchor, options.labelOffsetX, options.labelOffsetY)
end

template:AddMethods({
  ["GetFormLabelDimensions"] = function(self)
    local width, height = self._formLabel:GetSize()
    local options = self:GetOptions()
    return width, height, options.labelOffsetX, options.labelOffsetY
  end,
  ["GetFormLabel"] = function(self)
    return self._formLabel:GetText()
  end,
  ["SetFormLabel"] = function(self, text)
    self._formLabel:SetText(text)
    self:FireCustomScriptEvent("OnLabelChange", text)
  end,
  ["SetFormLabelParent"] = function(self, parentFrame)
    assertframe(parentFrame, "parentFrame", "SetFormLabelParent", 2)
    setFormLabelParent(self, parentFrame)
    self:FireCustomScriptEvent("OnLabelChange", self._formLabel:GetText())
  end,
})

function template:Create(frame, options)
  local label = addon:CreateFrame("Label", "$parentLabel", frame, options)
  label._formParent = frame

  frame._formLabel = label
  frame._formLabelParent = nil

  setFormLabelParent(frame, frame)
end