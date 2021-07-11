local _, addon = ...
local asserttype = addon.asserttype

local template = addon:NewFrame("Header")
template:AddMixin("RelativeSize")

template:SetDefaultOptions({
  header = "Header",
  relativeWidth = 1,
})

local function setLabelText(self, text)
  self._label:SetText(text)
  self:SetHeight(self._label:GetHeight())
end

template:AddMethods({
  ["GetText"] = function(self)
    return self._label:GetText()
  end,
  ["SetText"] = function(self, text)
    asserttype(text, "string", "text", "Header:SetText")
    setLabelText(self, text)
  end,
})

function template:Create(frame, options)
  local label = addon:CreateFrame("Label", nil, frame)
  label:SetPoint("CENTER", frame)

  --- Adapted from Ace3: AceGUIWidget-Heading.lua (see license information below)
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

  frame._label = label

  setLabelText(frame, options.header)
end

--[[
ACE3 LICENSE
Copyright (c) 2007, Ace3 Development Team All rights reserved. Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. * Redistribution of a stand alone version is strictly prohibited without prior written authorization from the Lead of the Ace3 Development Team. * Neither the name of the Ace3 Development Team nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]