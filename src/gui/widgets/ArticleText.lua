local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local widget = addon.CustomWidgets:NewWidget("ArticleText")

-- Unpacks either format { r = r, g = g, b = b, a = a } or { r, g, b, a }
local function unpackRGBA(t)
  if t.r or t.g or t.b or t.a then
    return t.r or 0.0, t.g or 0.0, t.b or 0.0, t.a or 1.0
  else
    return t[1] or 0.0, t[2] or 0.0, t[3] or 0.0, t[4] or 1.0
  end
end

-- Unpacks either format { x = x, y = y } or { x, y }
local function unpackXY(t)
  if t.x or t.y then
    return t.x or 0, t.y or 0
  else
    return t[1] or 0, t[2] or 0
  end
end

-- Unpacks either format { l = l, r = r, t = t, b = b } or { l, r, t, b }
local function unpackLRTB(t)
  if t.l or t.r or t.t or t.b then
    return t.l or 0, t.r or 0, t.t or 0, t.b or 0
  else
    return t[1] or 0, t[2] or 0, t[3] or 0, t[4] or 0
  end
end

local globalDefaultTextStyle = {}
local globalDefaultPageStyle = {
  margins = { 6, 6, 6, 6 },
  spacing = 6
}

local textStyleHandlers = {
  inheritsFrom = nil, -- No handler, set when fs is created
  -- Custom fonts not supported yet
  -- fontObject = "",
  -- fontPath = "",
  -- fontSize = 0,
  indentedWordWrap = function(fs, v) fs:SetIndentedWordWrap(v) end,
  justifyH = function(fs, v) fs:SetJustifyH(v) end,
  justifyV = function(fs, v) fs:SetJustifyV(v) end,
  spacing = function(fs, v) fs:SetSpacing(v) end,
  shadowColor = function(fs, v) fs:SetShadowColor(unpackRGBA(v)) end,
  shadowOffset = function(fs, v) fs:SetShadowOffset(unpackXY(v)) end,
  textColor = function(fs, v) fs:SetTextColor(unpackRGBA(v)) end,
}

local function buildFontStrings(frame)
  local fontStrings = {}

  for _, tx in ipairs(frame.text) do
    local textStyle = frame.textStyles[tx.textStyleName]
    if not textStyle then
      addon.Logger:Warn("No style defined for:", tx.textStyleName)
      textStyle = frame.textStyles["default"]
    end
    local fontString = frame:CreateFontString(nil, "BACKGROUND", textStyle.inheritsFrom)
    fontString:SetText(tx.text)
    for k, v in pairs(textStyle) do
      local handler = textStyleHandlers[k]
      if handler then
        handler(fontString, v, textStyle)
      end
    end
    table.insert(fontStrings, fontString)
  end

  frame.fontStrings = fontStrings
end

local function applyTextToPage(frame)
  local l, r, t, b = unpackLRTB(frame.pageStyle.margins or globalDefaultPageStyle.margins)
  local parent = frame:GetParent()
  frame:ClearAllPoints()
  frame:SetPoint("TOPLEFT", parent, "TOPLEFT", l, -1*t)
  frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -1*r, b)

  -- First line of text anchors to the parent frame
  local paragraphSpacing = frame.pageStyle.spacing or globalDefaultPageStyle.spacing
  local anchorFrame, anchor1, anchor2, spacing = frame, "TOPLEFT", "TOPRIGHT", 0
  for _, fs in ipairs(frame.fontStrings) do
    fs:SetPoint("TOPLEFT", anchorFrame, anchor1, 0, -1*spacing)
    fs:SetPoint("TOPRIGHT", anchorFrame, anchor2, 0, -1*spacing)
    -- Subsequent text anchors to the previous line of text
    anchorFrame, anchor1, anchor2, spacing = fs, "BOTTOMLEFT", "BOTTOMRIGHT", paragraphSpacing
  end
end

local function widget_SetTextStyle(self, textStyleName, textStyle)
  if type(textStyle) == "string" then
    textStyle = { inheritsFrom = textStyle }
  end
  self.textStyles[textStyleName] = textStyle or globalDefaultTextStyle
end

local function widget_SetPageStyle(self, pageStyle)
  self.pageStyle = pageStyle or globalDefaultPageStyle
end

local function widget_AddText(self, text, textStyleName)
  table.insert(self.text, { text = text, textStyleName = textStyleName or "default" })
end

local function widget_GetFontString(self, i)
  return self.fontStrings[i]
end

local function widget_OnShow(self)
  if not self.fontStrings then
    -- Build the font strings the first time that the text is shown
    buildFontStrings(self)
    applyTextToPage(self)
  end
end

function widget:Create(parent, defaultTextStyle, pageStyle)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetAllPoints(true)
  -- frame:Hide()

  frame.fontStrings = nil
  frame.pageStyle = nil
  frame.textStyles = {}
  frame.text = {}

  frame.SetTextStyle = widget_SetTextStyle
  frame.SetPageStyle = widget_SetPageStyle
  frame.AddText = widget_AddText
  frame.GetFontString = widget_GetFontString

  frame:SetTextStyle("default", defaultTextStyle)
  frame:SetPageStyle(pageStyle)
  -- frame:SetScript("OnShow", widget_OnShow)
  -- bug: Added as a manual method because I couldn't get OnShow to work properly
  frame.Assemble = widget_OnShow

  return frame
end
