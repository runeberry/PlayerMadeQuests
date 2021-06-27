local _, addon = ...

local template = addon:NewFrame("MixinMovable")

template:SetDefaultOptions({
  movable = true,           -- [boolean] Should this frame be movable by dragging?
  movableAnchor = "TOP",    -- [string] Side anchor indicating where dragging should be enabled
  movableSize = nil,        -- [number] Indicates how large the draggable area should be
})

template:AddMethods({
  ["IsPositionLocked"] = function(self)
    return self._positionLocked == true
  end,
  ["LockPosition"] = function(self, flag)
    if flag == nil then flag = true end
    self._positionLocked = flag
  end,
  ["UnlockPosition"] = function(self)
    self._positionLocked = nil
  end
})

local dragRegionScripts = {
  ["OnDragStart"] = function(self)
    if self._positionLocked then return end
    self._window:StartMoving()
  end,
  ["OnDragStop"] = function(self)
    self._window:StopMovingOrSizing()
  end,
}

function template:Create(frame, options)
  -- This mixin can be disabled with a simple option flag
  if not options.movable then return end

  -- Create an invisible button over the region where dragging should cause the frame to move
  local dragRegion = addon:CreateFrame("Button", nil, frame)
  dragRegion:RegisterForDrag("LeftButton")
  dragRegion._window = frame
  addon:ApplyScripts(dragRegion, dragRegionScripts)

  if options.movableSize then
    -- If a size is specified, then only a certain "bar" of the frame is draggable
    local c1, c2 = addon:GetCornersFromSide(options.movableAnchor)
    dragRegion:SetPoint(c1, frame, c1)
    dragRegion:SetPoint(c2, frame, c2)
    dragRegion:SetHeight(options.movableSize)
  else
    -- If no size is specified, then the whole frame is draggable
    dragRegion:SetAllPoints(true)
  end
end