local _, addon = ...
local asserttype, assertf = addon.asserttype, addon.assertf

local template = addon:NewFrame("FormLabel")

local defaultOptions = {
  text = "",              -- [string] The text of the label
  anchor = "LEFT",        -- [string] The anchor of the parent frame to hook the fontString to
  padding = 2,            -- [number] Number of px to offset the font from its parent in the anchor direction
  offset = 0,             -- [XY] Additional position correction for fontString
  layer = "BACKGROUND",   -- [string] The drawing layer for the fontString
  clickable = false,      -- [boolean] True to enable mouse script events

  fontTemplate = nil,     -- [string] Set manually to override automatic behavior
}

local anchorOptions = {
  LEFT = {
    fontTemplate = "GameFontNormal",
    anchorHook = "RIGHT",
  },
  RIGHT = {
    fontTemplate = "GameFontNormal",
    anchorHook = "LEFT",
  },
  TOP = {
    fontTemplate = "GameFontNormalSmall",
    anchorHook = "BOTTOM",
  },
  BOTTOM = {
    fontTemplate = "GameFontNormalSmall",
    anchorHook = "TOP",
  },
  TOPLEFT = {
    fontTemplate = "GameFontNormalSmall",
    anchorHook = "BOTTOMLEFT",
  },
  TOPRIGHT = {
    fontTemplate = "GameFontNormalSmall",
    anchorHook = "BOTTOMRIGHT",
  },
  BOTTOMLEFT = {
    fontTemplate = "GameFontNormalSmall",
    anchorHook = "TOPLEFT",
  },
  BOTTOMRIGHT = {
    fontTemplate = "GameFontNormalSmall",
    anchorHook = "TOPRIGHT",
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

  local _, padX, padY = addon:GetOffsetsFromPadding(options.anchor, options.padding)
  local offX, offY = addon:UnpackXY(options.offset)
  container:SetPoint(options.anchorHook, parent, options.anchor, padX + offX, padY + offY)

  local fontString = container:CreateFontString(frameName.."_FS", options.layer, options.fontTemplate)
  fontString:SetText(options.text)
  fontString:SetPoint("CENTER", container, "CENTER")

  -- Automatically size the container to fit the label text
  container:SetSize(fontString:GetStringWidth(), fontString:GetStringHeight())

  container._options = options
  container._fontString = fontString

  return container
end