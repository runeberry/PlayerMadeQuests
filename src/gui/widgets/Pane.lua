local _, addon = ...
local CreateFrame = addon.G.CreateFrame
local Anchors = addon.Anchors

-- todo: Never finished developing this widget, but keeping this here in case I want to work on it in the future
local widget = addon.CustomWidgets:NewWidget("Pane-WIP")

local defaultOptions = {
  anchor = Anchors.LEFT, --
  margin = 0, -- Space between a frame and the edge of the pane
  spacing = 0, -- Space between frames within the pane
  height = nil, -- Height of created frames, will fit to pane if nil
  width = nil, -- Width of created frames, will fit to pane if nil,
  wrap = false, -- Wrap frames to the next row/column?
}

local methods = {
  --- Creates a new empty Frame as a child of this Pane and adds it to the Pane's layout.
  --- The created Frame is returned.
  ["CreateFrame"] = function(self, options)
    local frame = CreateFrame("Frame", nil, self)

    options = addon:MergeTable(self._options, options or {})

    self:AddFrame(frame, options)
    return frame
  end,
  --- Adds the provided Frame to the Pane's layout.
  ["AddFrame"] = function(self, frame, options)
    assert(type(frame) == "table", "A child frame must be provided to AddFrame")

    options = addon:MergeTable(self._options, options or {})

    local anchor = options.anchor

    -- This new child frame needs to be anchored relative to the
    -- last frame that was added at this anchor point
    local lastFrame
    for _, f in ipairs(self._frames) do
      if (f._paneAnchor == options.anchor) then
        lastFrame = f
      end
    end



    local parent, pAnchor, offset
    if lastFrame then
      parent = lastFrame
      pAnchor = addon:GetOppositeAnchor(anchor)
      offset = addon:GetOffsetDirection(anchor) * options.spacing * 2
    else
      parent = self
      pAnchor = options.anchor
      offset = addon:GetOffsetDirection(anchor) * options.margin * 2
    end

    if options.wrap then
      local doWrap = self:GetHeight()
    end

    frame:SetPoint(anchor, parent, pAnchor, offx, offy)

    frame._paneAnchor = anchor
    table.insert(self._frames, frame)
  end,
}

function widget:Create(parent, options)
  if options then
    options = addon:MergeTable(defaultOptions, options)
  else
    options = addon:CopyTable(options)
  end

  local frame = CreateFrame("Frame", nil, parent)

  frame._frames = {}
  frame._options = options

  addon:ApplyMethods(frame, methods)

  return frame
end