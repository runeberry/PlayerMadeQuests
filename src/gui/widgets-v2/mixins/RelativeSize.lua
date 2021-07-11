local _, addon = ...
local asserttype, assertframe = addon.asserttype, addon.assertframe

local template = addon:NewMixin("RelativeSize")

template:SetDefaultOptions({
  relativeWidth = nil,      -- [number] Ratio of parent width (1 = full width)
  relativeWidthOffset = 0,  -- [number] Additional width after adjusting to match parent
  relativeHeight = nil,     -- [number] Ratio of parent height (1 = full height)
  relativeHeightOffset = 0, -- [number] Additional height after adjusting to match parent
})

local function resizeWidth(frame, parent)
  if not frame._relativeWidth then return end

  local width = parent:GetWidth() * frame._relativeWidth + (frame._relativeWidthOffset or 0)
  frame:SetWidth(width)
end

local function resizeHeight(frame, parent)
  if not frame._relativeHeight then return end

  local height = parent:GetHeight() * frame._relativeHeight + (frame._relativeHeightOffset or 0)
  frame:SetHeight(height)
end

local function addRelativeChild(frame, parent)
  local relativeChildren = parent._relativeChildren
  if not relativeChildren then
    relativeChildren = {}
    parent._relativeChildren = relativeChildren
  end

  relativeChildren[#relativeChildren+1] = frame
end

local function onParentSizeChanged(parent, width, height)
  if not parent._relativeChildren then return end

  for _, child in ipairs(parent._relativeChildren) do
    resizeWidth(child, parent)
    resizeHeight(child, parent)
  end
end

template:AddMethods({
  ["SetRelativeWidth"] = function(self, ratio, offset)
    asserttype(ratio, "number", "ratio", "SetRelativeWidth")
    self._relativeWidth = ratio

    if offset ~= nil then
      asserttype(offset, "number", "offset", "SetRelativeWidth")
      self._relativeWidthOffset = offset
    end

    resizeWidth(self, self:GetParent())
  end,
  ["SetRelativeHeight"] = function(self, ratio, offset)
    asserttype(ratio, "number", "ratio", "SetRealtiveHeight")
    self._relativeHeight = ratio

    if offset ~= nil then
      asserttype(offset, "number", "offset", "SetRelativeHeight")
      self._relativeHeightOffset = offset
    end

    resizeHeight(self, self:GetParent())
  end,
})

function template:Create(frame, options)
  if options.relativeWidth then
    frame:SetRelativeWidth(options.relativeWidth, options.relativeWidthOffset)
  end

  if options.relativeHeight then
    frame:SetRelativeHeight(options.relativeHeight, options.relativeHeightOffset)
  end

  local parent = frame:GetParent()
  addRelativeChild(frame, parent)
  parent:SetScript("OnSizeChanged", onParentSizeChanged)
end