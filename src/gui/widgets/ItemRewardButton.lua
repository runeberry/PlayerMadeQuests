local _, addon = ...
local CreateFrame = addon.G.CreateFrame
local asserttype = addon.asserttype

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
  ["GetItem"] = function(self)
    if not self._itemId then return nil end
    return addon:LookupItem(self._itemId)
  end,
  ["SetItem"] = function(self, itemId)
    if not itemId then
      -- Clear the item from the button
      self._itemId = nil
      -- todo: can I actually remove the item icon, etc. from the frame?
      return
    end

    local item = addon:LookupItem(itemId)
    if not item then
      addon.UILogger:Trace("ItemRewardButton item not found: %s", tostring(itemId))
      return
    end

    self._itemId = itemId

    SetItemButtonTexture(self, item.icon)
    SetItemButtonQuality(self, item.rarity, item.itemId)

    -- Name is provided by the *ItemButtonTemplate
    self.Name:SetText(item.name)

    self:SetTooltipContent({ itemId = item.itemId })
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
  end,

  ["EnableSelection"] = function(self, flag)
    if flag == nil then flag = true end
    self._selectable = flag
  end,
  ["GetSelected"] = function(self)
    return (self._selected and true) or false
  end,
  ["SetSelected"] = function(self, flag)
    if not self._selectable then return end
    if flag == nil then flag = true end
    self._selected = flag
    self.Highlight:SetShown(self._selected)
    if self._onSetSelected then
      addon:catch(function()
        self._onSetSelected(flag)
      end)
    end
  end,
  ["ToggleSelected"] = function(self)
    if not self._selectable then return end
    self:SetSelected(not self:GetSelected())
  end,
  ["OnSetSelected"] = function(self, handler)
    asserttype(handler, "function", "handler", "OnSelected")
    self._onSetSelected = handler
  end,
}

local scripts = {
  ["OnClick"] = function(self)
    self:ToggleSelected()
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

  frame.Highlight = frame:CreateTexture(nil, "BACKGROUND")
  frame.Highlight:SetTexture([[Interface\QuestFrame\UI-QuestItemHighlight]])
  frame.Highlight:SetBlendMode("ADD")
  -- The actual size of the highlight texture doesn't match up with the button at all
  -- so some wonky resizing needs to take place
  -- Based on the size info found here:
  -- https://github.com/Gethe/wow-ui-source/blob/classic/FrameXML/QuestInfo.xml#L442
  if options.large then
    frame.Highlight:SetPoint("TOPLEFT", frame, "TOPLEFT", -7, 7)
    frame.Highlight:SetSize(256, 64)
  else
    -- This doesn't actually line up right, but I don't think it's supposed to
    frame.Highlight:SetPoint("TOPLEFT", frame, "TOPLEFT", -7, 7)
    frame.Highlight:SetSize(224, 52)
  end
  frame.Highlight:Hide()

  -- This will add tooltip methods and scripts to the frame
  addon:AttachTooltip(frame)

  addon:ApplyMethods(frame, methods)

  for event, handler in pairs(scripts) do
    frame:SetScript(event, handler)
  end

  return frame
end