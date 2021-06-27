local _, addon = ...

local template = addon:NewMixin("Resizable")

template:SetDefaultOptions({
  resizable = true,           -- [boolean]
  minResize = 100,            -- [XY]
  maxResize = nil,            -- [XY]
  autoSave = true,            -- [boolean] Should this frame's size be saved whenever it's changed?
  autoLoad = true,            -- [boolean] Should this frame's saved size be set as soon as it's created?
})

template:AddMethods({
  ["IsSizeLocked"] = function(self)
    return self._sizeLocked == true
  end,
  ["LockSize"] = function(self, flag)
    if flag == nil then flag = true end
    self._sizeLocked = flag
  end,
  ["UnlockSize"] = function(self)
    self._sizeLocked = nil
  end,
})

local resizerScripts = {
  ["OnMouseDown"] = function(self)
    self:GetParent():StartSizing("BOTTOMRIGHT")
  end,
  ["OnMouseUp"] = function(self)
    local parent = self:GetParent()
    parent:StopMovingOrSizing()
    parent:SetUserPlaced(false) -- Bypass Blizzard's layout cache, we roll our own for finer control
  end,
}

--- Adapted from Ace3: AceGUIContainer-Window.lua (see license information below)
local function addSizerWidget(frame)
  local sizer = addon:CreateFrame("Frame", "Resizer%i", frame)
  sizer:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,0)
  sizer:SetWidth(25)
  sizer:SetHeight(25)
  sizer:EnableMouse()
  addon:ApplyScripts(sizer, resizerScripts)

  local line1 = sizer:CreateTexture(nil, "BACKGROUND")
  line1:SetWidth(14)
  line1:SetHeight(14)
  line1:SetPoint("BOTTOMRIGHT", -8, 8)
  line1:SetTexture(137057) -- Interface\\Tooltips\\UI-Tooltip-Border
  local x = 0.1 * 14/17
  line1:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)

  local line2 = sizer:CreateTexture(nil, "BACKGROUND")
  line2:SetWidth(8)
  line2:SetHeight(8)
  line2:SetPoint("BOTTOMRIGHT", -8, 8)
  line2:SetTexture(137057) -- Interface\\Tooltips\\UI-Tooltip-Border
  x = 0.1 * 8/17
  line2:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)
end

function template:Create(frame, options)
  -- This mixin can be disabled with a simple option flag
  if not options.resizable then return end

  frame:EnableMouse(true)
  frame:SetResizable(true)

  addSizerWidget(frame)

  frame._resizableBounds = {}

  if options.minResize then
    local width, height = addon:UnpackXY(options.minResize)
    frame:SetMinResize(width, height)
  end
  if options.maxResize then
    local width, height = addon:UnpackXY(options.maxResize)
    frame:SetMaxResize(width, height)
  end
end

--[[
ACE3 LICENSE
Copyright (c) 2007, Ace3 Development Team All rights reserved. Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. * Redistribution of a stand alone version is strictly prohibited without prior written authorization from the Lead of the Ace3 Development Team. * Neither the name of the Ace3 Development Team nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]