local _, addon = ...
local asserttype = addon.asserttype

local template = addon:NewFrame("MixinMovable")

template:SetDefaultOptions({
  movable = true,             -- [boolean] Should this frame be movable by dragging?
  movableWholeFrame = false,  -- [boolean] Should the whole frame be draggable? This will cover up any other mouse interaction.
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
  end,
  ["SetDragRegion"] = function(self, handler)
    asserttype(handler, "function", "handler", "SetDragRegion")

    self._movableDragRegion:ClearAllPoints()
    self._movableDragRegion:SetSize(0, 0)
    handler(self, self._movableDragRegion)
  end,
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

local function makeMovableWholeFrame(frame, dragRegion)
  dragRegion:SetAllPoints(true)
end

function template:Create(frame, options)
  -- This mixin can be disabled with a simple option flag
  if not options.movable then return end

  -- Create an invisible button over the region where dragging should cause the frame to move
  local dragRegion = addon:CreateFrame("Button", "$parentMovableDragRegion", frame)
  dragRegion:RegisterForDrag("LeftButton")
  dragRegion._window = frame
  addon:ApplyScripts(dragRegion, dragRegionScripts)

  frame._movableDragRegion = dragRegion

  if options.movableWholeFrame then
    frame:SetDragRegion(makeMovableWholeFrame)
  end
end