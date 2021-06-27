local _, addon = ...
local asserttype, assertframe = addon.asserttype, addon.assertframe

local template = addon:NewFrame("PopoutWindow")
template:AddMixin("MixinMovable")
template:AddMixin("MixinResizable")

template:SetDefaultOptions({
  title = "",      -- [string]
  width = 200,
  height = 200,

  movableSize = 28,
  resizable = false,
})

template:AddMethods({
  ["SetTitle"] = function(self, text)
    asserttype(text, "string", "text", "SetTitle")
    self._titleFontString:SetText(text)
  end,
  ["SetContent"] = function(self, content)
    assertframe(content, "content")

    if self._contentFrameContent then
      self._contentFrameContent:ClearAllPoints()
      self._contentFrameContent:Hide()
    end

    content:ClearAllPoints()
    content:SetParent(self._contentFrame)
    content:SetAllPoints(self._contentFrame)
    content:Show()
    self._contentFrameContent = content

    if content.Refresh and self:GetOptions().autoLoad then
      content:Refresh()
    end
  end,
  ["LockPosition"] = function(self, flag)
    if flag == nil then flag = true end
    self._positionLocked = flag
  end,
  ["UnlockPosition"] = function(self)
    self._positionLocked = nil
  end
})

--- Adapted from Ace3: AceGUIContainer-Window.lua (see license information below)
--- Which itself was adapted from UIPanelDialogTemplate, seen here:
---   https://github.com/Gethe/wow-ui-source/blob/live/SharedXML/SharedBasicControls.xml#L51
local function setWindowTextures(frame)
  local titlebg = frame:CreateTexture(nil, "BACKGROUND")
  titlebg:SetTexture(251966) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Title-Background
  titlebg:SetPoint("TOPLEFT", 9, -6)
  titlebg:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -28, -24)

  local dialogbg = frame:CreateTexture(nil, "BACKGROUND")
  dialogbg:SetTexture(137056) -- Interface\\Tooltips\\UI-Tooltip-Background
  dialogbg:SetPoint("TOPLEFT", 8, -24)
  dialogbg:SetPoint("BOTTOMRIGHT", -6, 8)
  dialogbg:SetVertexColor(0, 0, 0, .75)

  local topleft = frame:CreateTexture(nil, "BORDER")
  topleft:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
  topleft:SetWidth(64)
  topleft:SetHeight(64)
  topleft:SetPoint("TOPLEFT")
  topleft:SetTexCoord(0.501953125, 0.625, 0, 1)

  local topright = frame:CreateTexture(nil, "BORDER")
  topright:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
  topright:SetWidth(64)
  topright:SetHeight(64)
  topright:SetPoint("TOPRIGHT")
  topright:SetTexCoord(0.625, 0.75, 0, 1)

  local top = frame:CreateTexture(nil, "BORDER")
  top:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
  top:SetHeight(64)
  top:SetPoint("TOPLEFT", topleft, "TOPRIGHT")
  top:SetPoint("TOPRIGHT", topright, "TOPLEFT")
  top:SetTexCoord(0.25, 0.369140625, 0, 1)

  local bottomleft = frame:CreateTexture(nil, "BORDER")
  bottomleft:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
  bottomleft:SetWidth(64)
  bottomleft:SetHeight(64)
  bottomleft:SetPoint("BOTTOMLEFT")
  bottomleft:SetTexCoord(0.751953125, 0.875, 0, 1)

  local bottomright = frame:CreateTexture(nil, "BORDER")
  bottomright:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
  bottomright:SetWidth(64)
  bottomright:SetHeight(64)
  bottomright:SetPoint("BOTTOMRIGHT")
  bottomright:SetTexCoord(0.875, 1, 0, 1)

  local bottom = frame:CreateTexture(nil, "BORDER")
  bottom:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
  bottom:SetHeight(64)
  bottom:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMRIGHT")
  bottom:SetPoint("BOTTOMRIGHT", bottomright, "BOTTOMLEFT")
  bottom:SetTexCoord(0.376953125, 0.498046875, 0, 1)

  local left = frame:CreateTexture(nil, "BORDER")
  left:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
  left:SetWidth(64)
  left:SetPoint("TOPLEFT", topleft, "BOTTOMLEFT")
  left:SetPoint("BOTTOMLEFT", bottomleft, "TOPLEFT")
  left:SetTexCoord(0.001953125, 0.125, 0, 1)

  local right = frame:CreateTexture(nil, "BORDER")
  right:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
  right:SetWidth(64)
  right:SetPoint("TOPRIGHT", topright, "BOTTOMRIGHT")
  right:SetPoint("BOTTOMRIGHT", bottomright, "TOPRIGHT")
  right:SetTexCoord(0.1171875, 0.2421875, 0, 1)
end

function template:Create(frame, options)
  frame:SetFrameStrata("FULLSCREEN_DIALOG")
  frame:SetMovable(true)
  frame:EnableMouse(true)

  setWindowTextures(frame)

  local closeButton = addon:CreateFrame("Button", "$parentCloseButton", frame, "UIPanelCloseButton")
  closeButton:SetPoint("TOPRIGHT", 2, 1)

  local titleFontString = frame:CreateFontString("$parentTitleFS", "ARTWORK")
  titleFontString:SetFontObject("GameFontNormal")
  titleFontString:SetPoint("TOPLEFT", 12, -8)
  titleFontString:SetPoint("TOPRIGHT", -32, -8)

  local contentFrame = addon:CreateFrame("Frame", "$parentContent", frame)
  -- todo: lazy frame padding, make better?
  contentFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -28)
  contentFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 12)
  contentFrame:SetClipsChildren(true)

  frame._closeButton = closeButton
  frame._titleFontString = titleFontString
  frame._contentFrame = contentFrame

  frame:SetTitle(options.title)
  frame:SetSize(options.width, options.height)
end

--[[
ACE3 LICENSE
Copyright (c) 2007, Ace3 Development Team All rights reserved. Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. * Redistribution of a stand alone version is strictly prohibited without prior written authorization from the Lead of the Ace3 Development Team. * Neither the name of the Ace3 Development Team nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]