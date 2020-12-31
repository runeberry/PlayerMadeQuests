local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local widget = addon.CustomWidgets:NewWidget("TitleBar")

local function closeOnClick(self)
  addon:PlaySound("CloseWindow")
  self._frame:Hide()
  if self._frame._onClose then
    self._frame:_onClose()
  end
end

local methods = {
  ["SetTitleText"] = function(self, text)
    self._fontString:SetText(text)
  end,
  ["OnClose"] = function(self, fn)
    self._onClose = fn
  end
}

function widget:Create(frame, options)
  options = options or {}
  local titleBar = CreateFrame("Frame", nil, frame)
  titleBar:EnableMouse(true)
  titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT")
  titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT")

  if options.texture then
    local titlebg = frame:CreateTexture(nil, "BACKGROUND")
    titlebg:SetTexture(options.texture)
    titlebg:SetPoint("TOPLEFT", 9, -6)
    titlebg:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -28, -24)
  end

  if options.height then
    titleBar:SetHeight(options.height)
  else
    titleBar:SetHeight(24)
  end

  local close = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", 2, 1)
  close:SetScript("OnClick", closeOnClick)
  close._frame = frame

  local titletext = frame:CreateFontString(nil, "ARTWORK")
  titletext:SetFontObject("GameFontNormal")
  titletext:SetPoint("TOPLEFT", 12, -8)
  titletext:SetPoint("TOPRIGHT", -32, -8)

  if options.text then
    titletext:SetText(options.text)
  end

  titleBar._fontString = titletext

  addon:ApplyMethods(frame, methods)

  return titleBar
end