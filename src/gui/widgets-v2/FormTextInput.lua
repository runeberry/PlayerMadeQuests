local _, addon = ...

local template = addon:NewFrame("FormTextInput")

template:RegisterCustomScriptEvent("OnSubmit")

local defaultOptions = {
  label = "",               -- [string]
  multiline = false,        -- [boolean]
  autoFocus = false,        -- [boolean]
  textInset = 0,            -- [LRTB]
  defaultText = "",         -- [string]
  width = 100,              -- [number]

  frameTemplate = "InputBoxTemplate",
  fontTemplate = "ChatFontNormal",
  labelFontTemplate = "GameFontHighlightSmall",
  labelJustifyH = "LEFT",

  clearFocusOnEnter = true,
  clearFocusOnEscape = true,
  submitOnEnter = true,
}

template:AddMethods({
  ["SetLabel"] = function(self, text)
    self._label:SetText(text or "")
  end,
})

template:AddScripts({
  ["OnEnterPressed"] = function(self)
    local options = self._options

    -- Don't mess with the Enter behavior of a multiline EditBox
    if options.multiline then return end

    -- OnSubmit will only react to single-line text boxes
    if options.submitOnEnter then
      self:FireCustomScriptEvent("OnSubmit", self:GetText())
    end
    if options.clearFocusOnEnter then
      self:ClearFocus()
    end
  end,
  ["OnEscapePressed"] = function (self)
    local options = self._options

    if options.clearFocusOnEscape then
      self:ClearFocus()
    end
  end,
  ["OnTextChanged"] = function(self, isUserInput)

  end,
  ["OnSubmit"] = function(self, text)

  end,
})

function template:Create(frameName, parent, options)
  options = addon:MergeOptionsTable(defaultOptions, options)

  local editBox = addon:CreateFrame("EditBox", frameName, parent, options.frameTemplate)
  editBox:SetAutoFocus(options.autoFocus)
  editBox:SetFontObject(options.fontTemplate)
  editBox:SetMultiLine(options.multiline)
  editBox:SetText(options.defaultText)

  local insetL, insetR, insetT, insetB = addon:UnpackLRTB(options.textInset)
  editBox:SetTextInsets(insetL, insetR, insetT, insetB)

  -- local _, height = editBox:GetFont()
  -- if options.multiline then
  --   height = height * 3
  -- end
  -- editBox:SetSize(options.width, height)

  -- todo: still need this?
  -- addon:ApplyBackgroundStyle(editBox)

  local labelOpts = {
    text = options.label,
    anchor = "TOPLEFT",
  }
  local label = addon:CreateFrame("FormLabel", frameName.."Label", editBox, labelOpts)

  editBox._options = options
  editBox._label = label

  return editBox
end