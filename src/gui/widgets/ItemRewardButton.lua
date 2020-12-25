local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local SetItemButtonCount = addon.G.SetItemButtonCount
local SetItemButtonStock = addon.G.SetItemButtonStock
local SetItemButtonTexture = addon.G.SetItemButtonTexture
local SetItemButtonTextureVertexColor = addon.G.SetItemButtonTextureVertexColor
local SetItemButtonDesaturated = addon.G.SetItemButtonDesaturated
local SetItemButtonNormalTextureVertexColor = addon.G.SetItemButtonNormalTextureVertexColor
local SetItemButtonNameFrameVertexColor = addon.G.SetItemButtonNameFrameVertexColor
local SetItemButtonSlotVertexColor = addon.G.SetItemButtonSlotVertexColor
local SetItemButtonQuality = addon.G.SetItemButtonQuality
local HandleModifiedItemClick = addon.G.HandleModifiedItemClick

local widget = addon.CustomWidgets:NewWidget("ItemRewardButton")

local defaultOptions = {
  large = false, -- Should this use "LargeItemButtonTemplate"?
}

local methods = {
  ["SetItem"] = function(self, itemId)
    local item = addon:LookupItem(itemId)

    SetItemButtonTexture(self, item.icon)
    SetItemButtonQuality(self, item.rarity, item.id)

    -- Name is provided by the *ItemButtonTemplate
    self.Name:SetText(item.name)

    self:SetTooltipContent({ itemId = item.id })
  end,
  ["SetItemCount"] = function(self, count)
    SetItemButtonCount(self, count, false)
  end,
  -- Colors the button red if it's not usable
  ["SetItemUsable"] = function(self, isUsable)
    if isUsable then
      SetItemButtonTextureVertexColor(self, 1.0, 1.0, 1.0)
      SetItemButtonNameFrameVertexColor(self, 1.0, 1.0, 1.0)
    else
      SetItemButtonTextureVertexColor(self, 0.9, 0, 0)
      SetItemButtonNameFrameVertexColor(self, 0.9, 0, 0)
    end
  end
}

function widget:Create(parent, options)
  options = addon:MergeOptionsTable(defaultOptions, options)

  local template = "SmallItemButtonTemplate"
  if options.large then
    template = "LargeItemButtonTemplate"
  end

  -- Frame name is required for tooltips (I think)
  local name = addon:CreateGlobalName("ItemRewardButton_%i")
  local frame = CreateFrame("Button", name, parent, template)

  -- IconBorder and IconOverlay are unfortunately required by the Set* global functions
  frame.IconBorder = frame:CreateTexture(nil, "OVERLAY")
  -- frame.IconBorder:SetTexture([[Interface\Common\WhiteIconFrame]])
  -- frame.IconBorder:SetPoint("TOPLEFT", frame.Icon, "TOPLEFT")
  -- frame.IconBorder:SetPoint("BOTTOMRIGHT", frame.Icon, "BOTTOMRIGHT")

  frame.IconOverlay = frame:CreateTexture(nil, "OVERLAY")
  -- frame.IconOverlay:SetPoint("TOPLEFT", frame.Icon, "TOPLEFT")
  -- frame.IconOverlay:SetPoint("BOTTOMRIGHT", frame.Icon, "BOTTOMRIGHT")

  -- This will add tooltip methods and scripts to the frame
  addon:AttachTooltip(frame)

  addon:ApplyMethods(frame, methods)

  return frame
end