-- Adapted from the sizer sub-widget found in AceGUI
local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local widget = addon.CustomWidgets:NewWidget("Sizer")

local function sizerseOnMouseDown(self)
  self:GetParent():StartSizing("BOTTOMRIGHT")
end

local function sizersOnMouseDown(self)
  self:GetParent():StartSizing("BOTTOM")
end

local function sizereOnMouseDown(self)
  self:GetParent():StartSizing("RIGHT")
end

local function sizerOnMouseUp(self)
  local frame = self:GetParent()
  frame:StopMovingOrSizing()
  if frame._onResize then
    frame:_onResize()
  end
end

local methods = {
  ["OnResize"] = function(self, fn)
    self._onResize = fn
  end,
}

function widget:Create(frame)
  local sizer_se = CreateFrame("Frame",nil,frame)
  sizer_se:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,0)
  sizer_se:SetWidth(25)
  sizer_se:SetHeight(25)
  sizer_se:EnableMouse()
  sizer_se:SetScript("OnMouseDown",sizerseOnMouseDown)
  sizer_se:SetScript("OnMouseUp", sizerOnMouseUp)
  self.sizer_se = sizer_se

  local line1 = sizer_se:CreateTexture(nil, "BACKGROUND")
  self.line1 = line1
  line1:SetWidth(14)
  line1:SetHeight(14)
  line1:SetPoint("BOTTOMRIGHT", -8, 8)
  line1:SetTexture(137057) -- Interface\\Tooltips\\UI-Tooltip-Border
  local x = 0.1 * 14/17
  line1:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)

  local line2 = sizer_se:CreateTexture(nil, "BACKGROUND")
  self.line2 = line2
  line2:SetWidth(8)
  line2:SetHeight(8)
  line2:SetPoint("BOTTOMRIGHT", -8, 8)
  line2:SetTexture(137057) -- Interface\\Tooltips\\UI-Tooltip-Border
  local x = 0.1 * 8/17
  line2:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)

  local sizer_s = CreateFrame("Frame",nil,frame)
  sizer_s:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-25,0)
  sizer_s:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",0,0)
  sizer_s:SetHeight(25)
  sizer_s:EnableMouse()
  sizer_s:SetScript("OnMouseDown",sizersOnMouseDown)
  sizer_s:SetScript("OnMouseUp", sizerOnMouseUp)
  self.sizer_s = sizer_s

  local sizer_e = CreateFrame("Frame",nil,frame)
  sizer_e:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,25)
  sizer_e:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,0)
  sizer_e:SetWidth(25)
  sizer_e:EnableMouse()
  sizer_e:SetScript("OnMouseDown",sizereOnMouseDown)
  sizer_e:SetScript("OnMouseUp", sizerOnMouseUp)
  self.sizer_e = sizer_e

  frame:EnableMouse(true)
  frame:SetResizable(true)

  for fname, fn in pairs(methods) do
    frame[fname] = fn
  end

  -- The sizer itself is not contained within a frame, but rather applied
  -- to the parent frame. So there isn't really a valid "widget" to return
  return frame
end