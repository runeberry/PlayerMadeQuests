local _, addon = ...

local widget = addon.CustomWidgets:NewWidget("ScriptEditor")

local cursorMarker = "\2"

local function setCursorMarker(text, pos)
  return text:sub(1, pos)..cursorMarker..text:sub(pos + 1)
end

local function remCursorMarker(text)
  return text:gsub(cursorMarker, ""), text:find(cursorMarker) - 1
end

local function widget_OnTextChanged(self, isUserInput)
  if isUserInput then
    local text, pos = self:GetText(true), self.editBox:GetCursorPosition()
    text = setCursorMarker(text, pos)
    text = addon:ApplyYamlColors(text, pos)
    -- if lineChanged then
    --   doIndentation()
    -- end
    text, pos = remCursorMarker(text)
    self:SetText(text)
    self.editBox:SetCursorPosition(pos)
  end
end

function widget:Create(parent, labelText, editBoxText)
  local textInputScrolling = addon.CustomWidgets:CreateWidget("TextInputScrolling", parent, labelText, editBoxText)
  textInputScrolling:OnTextChanged(widget_OnTextChanged)
  -- addon.Indent.enable(textInputScrolling.editBox)
  return textInputScrolling
end
