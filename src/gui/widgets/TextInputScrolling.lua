local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local widget = addon.CustomWidgets:NewWidget("TextInputScrolling")

local labelSpacer = "  "
local textInset = 8
local scrollDelay = 0.033 -- approximately 1 frame @ 30 FPS

local editBoxScripts = {
  -- todo: scrolling is a little buggy when you insert a new line
  -- possibly because OnCursorChanged is fired twice when Enter is pressed
  ["OnCursorChanged"] = function(editBox, xPos, yPos, _, lineHeight)
    -- Cool formula, but I don't need it right now
    -- local lineNum = math.floor((-1*yPos / lineHeight) + 0.5) + 1

    local scrollFrame = editBox._widget.scrollFrame
    local vs = scrollFrame:GetVerticalScroll()
    local h = scrollFrame:GetHeight()

    yPos = -1*yPos -- Easier to work with a positive yPos
    if yPos + lineHeight > vs + h then
      -- Cursor is below the visible area
      local scroll = math.ceil(yPos + lineHeight - h)
      scrollFrame:SetVerticalScroll(scroll)
      -- addon.Logger:Debug("Scrolled down from", vs, "to", scroll, "at Y:", yPos)
    elseif yPos < vs then
      -- Cursor is above the visible area
      local scroll = yPos
      scrollFrame:SetVerticalScroll(scroll)
      -- addon.Logger:Debug("Scrolled up from", vs, "to", scroll, "at Y:", yPos)
    end
  end,
  ["OnEscapePressed"] = function(editBox)
    if editBox._widget.clearFocusOnEscape then
      editBox:ClearFocus()
    end
  end,
  ["OnTextChanged"] = function(editBox, isUserInput)
    if isUserInput then
      editBox._widget.isDirty = true
    end
  end
}

local widgetMethods = {
  ["GetText"] = function(self)
    return self.editBox:GetText()
  end,
  ["IsDirty"] = function(self)
    return self.isDirty or false
  end,
  ["ScrollTo"] = function(self, anchor, offset)
    anchor, offset = anchor or "TOP", offset or 0
    if anchor == "TOP" then
      self.scrollFrame:SetVerticalScroll(offset)
    elseif anchor == "BOTTOM" then
      offset = self.scrollFrame:GetHeight() - offset
      self.scrollFrame:SetVerticalScroll(offset)
    end
  end,
  ["SetDirty"] = function(self, bool)
    self.isDirty = bool
  end,
  ["SetEnabled"] = function(self, flag)
    if flag == nil then flag = true end
    self.editBox:SetEnabled(flag)
  end,
  ["SetLabel"] = function(self, text)
    text = text or ""
    self.label:SetText(labelSpacer..text)
  end,
  ["SetText"] = function(self, text)
    self.editBox:SetText(text or "")
    addon.Ace:ScheduleTimer(function()
      -- Force the scrollFrame to start at the top whenever the text is changed
      -- Seems the WoW client can't correctly set scroll until the next frame
      self.scrollFrame:SetVerticalScroll(0)
    end, scrollDelay)
  end,
}

function widget:Create(parent, labelText, editBoxText)
  labelText = labelText or ""
  editBoxText = editBoxText or ""

  local frame = CreateFrame("Frame", nil, parent)
  frame:SetPoint("TOPLEFT", parent, "TOPLEFT")
  frame:SetPoint("TOPRIGHT", parent, "TOPRIGHT")
  frame:SetHeight(1) -- Frame must have >0 height when text is set or text won't show

  local label = frame:CreateFontString(nil, "BACKGROUND")
  label:SetFontObject("GameFontHighlightSmall")
  label:SetJustifyH("LEFT")
  label:SetText(labelSpacer..labelText)
  label:SetPoint("TOPLEFT", frame, "TOPLEFT")

  local editBoxBorderFrame = CreateFrame("Frame", nil, frame)
  addon:ApplyBackgroundStyle(editBoxBorderFrame)
  editBoxBorderFrame:SetPoint("TOPLEFT", label, "BOTTOMLEFT")
  editBoxBorderFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

  local scrollFrame, scrollBarFrame = addon:CreateScrollFrame(editBoxBorderFrame)
  scrollBarFrame:SetPoint("TOPRIGHT", editBoxBorderFrame, "TOPRIGHT")
  -- bug: scrollbar offset-x doesn't work so it falls out of the frame... why?
  scrollBarFrame:SetPoint("BOTTOMRIGHT", editBoxBorderFrame, "BOTTOMRIGHT", -2, 0)
  scrollFrame:SetPoint("TOPLEFT", editBoxBorderFrame, "TOPLEFT", textInset, -1*textInset)
  scrollFrame:SetPoint("BOTTOMRIGHT", scrollBarFrame, "BOTTOMLEFT", -1*textInset, textInset)

  local editBox = CreateFrame("EditBox", nil, scrollFrame)
  editBox:SetMultiLine(true)
  editBox:SetAutoFocus(false)
  editBox:SetFontObject("ChatFontNormal")
  editBox:SetText(editBoxText)
  editBox:SetWidth(scrollFrame:GetWidth())
  addon.CustomWidgets:ApplyScripts(frame, editBox, editBoxScripts)

  -- Wrap an invisible button over the editBox frame to expand its clickable area
  local clickHandler = CreateFrame("Button", nil, editBoxBorderFrame)
  clickHandler:SetAllPoints(true)
  clickHandler:SetScript("OnClick", function()
    editBox:SetFocus()
    editBox:HighlightText(0, 0)
    editBox:SetCursorPosition(#(editBox:GetText()))
  end)

  scrollFrame:SetScrollChild(editBox)

  editBox._widget = frame
  frame.label = label
  frame.editBox = editBox
  frame.scrollFrame = scrollFrame

  frame.clearFocusOnEscape = true

  for name, fn in pairs(widgetMethods) do
    frame[name] = fn
  end

  return frame
end