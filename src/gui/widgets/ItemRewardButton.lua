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
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
    itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID,
    isCraftingReagent = addon.G.GetItemInfo(itemId)

    -- local _, itemType, itemSubType, itemEquipLoc, itemIcon, itemClassID, itemSubClassID = GetItemInfoInstant(itemId)

    SetItemButtonTexture(self, itemIcon)
    SetItemButtonQuality(self, itemRarity, itemId)

    -- Name is provided by the *ItemButtonTemplate
    self.Name:SetText(itemName)

    self:SetTooltipContent({ itemId = itemId })
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
  if options then
    options = addon:MergeTable(defaultOptions, options)
  else
    options = addon:CopyTable(defaultOptions)
  end

  local template = "SmallItemButtonTemplate"
  if options.large then
    template = "LargeItemButtonTemplate"
  end

  -- Frame name is required for tooltips (I think)
  local name = addon:CreateID("PMQ_ItemRewardButton_%i")
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

  for fname, fn in pairs(methods) do
    frame[fname] = fn
  end

  return frame
end