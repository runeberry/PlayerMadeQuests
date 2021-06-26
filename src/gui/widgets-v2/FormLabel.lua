local _, addon = ...
local asserttype, assertf, assertframe = addon.asserttype, addon.assertf, addon.assertframe

local template = addon:NewFrame("FormLabel")
template:RegisterCustomScriptEvent("OnFormLabelChange")

template:SetDefaultOptions({
  label = "",                  -- [string] The text of the label
  labelAnchor = "LEFT",        -- [string] The anchor of the parent frame to hook the fontString to
  labelLayer = "BACKGROUND",   -- [string] The drawing layer for the fontString
  labelClickable = false,      -- [boolean] True to enable mouse script events

  -- Specify the following settings only if you want to override anchor-specific options
  labelFontTemplate = nil,     -- [string]
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

local function setFormLabel(self, text)
  self._labelFontString:SetText(text)

  -- Refresh label size
  local width, height = self._labelFontString:GetSize()
  self:SetSize(width, height)
end

local function setFormLabelParent(self, parentFrame)
  self._labelParent = parentFrame

  -- Refresh label position
  local options = self:GetOptions()
  local labelParent = self._labelParent or self
  self._labelFontString:ClearAllPoints(true)
  self._labelFontString:SetPoint(options.labelAnchorHook, labelParent, options.labelAnchor, options.labelOffsetX, options.labelOffsetY)
end

template:AddMethods({
  ["GetFormLabel"] = function(self)
    return self._labelFontString
  end,
  ["GetFormLabelDimensions"] = function(self)
    local width, height = self._labelFontString:GetSize()
    local options = self:GetOptions()
    return width, height, options.labelOffsetX, options.labelOffsetY
  end,
  ["SetFormLabel"] = function(self, text)
    asserttype(text, "string", "text", "SetFormLabel")
    setFormLabel(self, text)
    self:FireCustomScriptEvent("OnFormLabelChange")
  end,
  ["SetFormLabelParent"] = function(self, parentFrame)
    assertframe(parentFrame, "parentFrame", "SetFormLabelParent", 2)
    setFormLabelParent(self, parentFrame)
    self:FireCustomScriptEvent("OnFormLabelChange")
  end,
})

function template:Create(frame, options)
  if options.labelClickable then
    frame:EnableMouse(true)
  end

  local labelName = addon:CreateGlobalName("FormLabel_FS%i")
  local fontString = frame:CreateFontString(labelName, options.labelLayer, options.labelFontTemplate)

  frame._labelFontString = fontString
  frame._labelParent = nil

  setFormLabel(frame, options.label)
  setFormLabelParent(frame, frame)
end