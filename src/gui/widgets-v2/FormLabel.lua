local _, addon = ...
local asserttype, assertf = addon.asserttype, addon.assertf

local template = addon:NewFrame("FormLabel")

local defaultOptions = {
  text = "",              -- [string] The text of the label
  anchor = "LEFT",        -- [string] The anchor of the parent frame to hook the fontString to
  layer = "BACKGROUND",   -- [string] The drawing layer for the fontString
  clickable = false,      -- [boolean] True to enable mouse script events

  -- Specify the following settings only if you want to override anchor-specific options
  fontTemplate = nil,     -- [string]
  offsetX = nil,          -- [number]
  offsetY = nil,          -- [number]
}

local anchorOptions = {
  LEFT = {
    fontTemplate = "GameFontNormal",
    anchorHook = "RIGHT",
    offsetX = -2,
    offsetY = 0,
  },
  RIGHT = {
    fontTemplate = "GameFontNormal",
    anchorHook = "LEFT",
    offsetX = 2,
    offsetY = 0,
  },
  TOP = {
    fontTemplate = "GameFontNormalSmall",
    anchorHook = "BOTTOM",
    offsetX = 0,
    offsetY = 2,
  },
  BOTTOM = {
    fontTemplate = "GameFontNormalSmall",
    anchorHook = "TOP",
    offsetX = 0,
    offsetY = -2,
  },
  TOPLEFT = {
    fontTemplate = "GameFontNormalSmall",
    anchorHook = "BOTTOMLEFT",
    offsetX = 0,
    offsetY = 2,
  },
  TOPRIGHT = {
    fontTemplate = "GameFontNormalSmall",
    anchorHook = "BOTTOMRIGHT",
    offsetX = 0,
    offsetY = 2,
  },
  BOTTOMLEFT = {
    fontTemplate = "GameFontNormalSmall",
    anchorHook = "TOPLEFT",
    offsetX = 0,
    offsetY = -2,
  },
  BOTTOMRIGHT = {
    fontTemplate = "GameFontNormalSmall",
    anchorHook = "TOPRIGHT",
    offsetX = 0,
    offsetY = -2,
  },
  CENTER = nil, -- Not supported
}

template:AddMethods({
  ["GetText"] = function(self)
    return self._fontString:GetText()
  end,
  ["SetText"] = function(self, text, resize)
    if resize == nil then resize = true end

    self._fontString:SetText(tostring(text))

    if resize then
      self:SetWidth(self._fontString:GetStringWidth())
    end
  end,
  ["GetFontString"] = function(self)
    return self._fontString
  end,
})

function template:Create(frameName, parent, options)
  options = addon:MergeOptionsTable(defaultOptions, options)
  assertf(anchorOptions[options.anchor], "FormLabel:Create - %s is not a supported anchor", options.anchor)
  options = addon:MergeOptionsTable(anchorOptions[options.anchor], options)

  local container = addon:CreateFrame("Frame", frameName, parent)
  if options.clickable then
    container:EnableMouse(true)
  end

  container:SetPoint(options.anchorHook, parent, options.anchor, options.offsetX, options.offsetY)

  local fontString = container:CreateFontString(frameName.."_FS", options.layer, options.fontTemplate)
  fontString:SetText(options.text)
  fontString:SetPoint("CENTER", container, "CENTER")

  -- Automatically size the container to fit the label text
  container:SetSize(fontString:GetStringWidth(), fontString:GetStringHeight())

  container._options = options
  container._fontString = fontString

  return container
end