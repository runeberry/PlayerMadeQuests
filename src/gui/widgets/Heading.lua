local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local widget = addon.CustomWidgets:NewWidget("Heading")

local function widget_SetText(self, text)
  self.label:SetText(text or "")
  if text and text ~= "" then
    self.left:SetPoint("RIGHT", self.label, "LEFT", -5, 0)
    self.right:Show()
  else
    self.left:SetPoint("RIGHT", -3, 0)
    self.right:Hide()
  end
end

-- Adapted from AceGUI's heading
function widget:Create(parent, text)
  local frame = CreateFrame("Frame", nil, parent)
  frame:Hide()

	local label = frame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	label:SetPoint("TOP")
	label:SetPoint("BOTTOM")
	label:SetJustifyH("CENTER")

	local left = frame:CreateTexture(nil, "BACKGROUND")
	left:SetHeight(8)
	left:SetPoint("LEFT", 3, 0)
	left:SetPoint("RIGHT", label, "LEFT", -5, 0)
	left:SetTexture(137057) -- Interface\\Tooltips\\UI-Tooltip-Border
	left:SetTexCoord(0.81, 0.94, 0.5, 1)

	local right = frame:CreateTexture(nil, "BACKGROUND")
	right:SetHeight(8)
	right:SetPoint("RIGHT", -3, 0)
	right:SetPoint("LEFT", label, "RIGHT", 5, 0)
	right:SetTexture(137057) -- Interface\\Tooltips\\UI-Tooltip-Border
  right:SetTexCoord(0.81, 0.94, 0.5, 1)

  frame.label = label
  frame.left = left
  frame.right = right
  frame.SetText = widget_SetText

  frame:SetHeight(18)
  frame:SetText(text)

  return frame
end