local _, addon = ...
local GameTooltip = addon.G.GameTooltip

local tooltipDelay = 0 -- Delay to show tooltip, in seconds

-- Share one tooltip frame and cancel token between all tooltips
local tooltip
local tooltipCancelToken

addon:OnGuiReady(function()
  tooltip = GameTooltip
  -- tooltip = CreateFrame("GameTooltip", "PMQ_CustomTooltip", nil, "GameTooltipTemplate")
end)

local methods = {
  -- Use this method to manually show the tooltip
  ["ShowTooltip"] = function(self)
    local anchor = self._tooltipAnchor
    local content = self._tooltipContent

    if not anchor then
      addon.UILogger:Trace("Failed to ShowTooltip - no anchor point is set")
      return
    elseif not content then
      addon.UILogger:Trace("Failed to Showtooltip - no content is set")
      return
    end

    tooltip:SetOwner(anchor.frame, "ANCHOR_NONE")
    tooltip:SetPoint(anchor.p1, anchor.frame, anchor.p2, anchor.x, anchor.y)

    if content.itemId then
      tooltip:SetItemByID(content.itemId)
    else
      if content.text then
        tooltip:AddLine(content.text)
      end
      if content.description then
        if not content.text then
          -- If no primary text was added, add a blank line so we can get to the 2nd line's formatting
          tooltip:AddLine("")
        end
        tooltip:AddLine(content.description)
      end
    end

    tooltip:Show()
  end,
  -- Use this method to manually hide the tooltip
  ["HideTooltip"] = function(self)
    tooltip:Hide()
  end,
  ["SetTooltipAnchor"] = function(self, p1, anchorFrame, p2, x, y)
    self._tooltipAnchor = {
      p1 = p1,
      frame = anchorFrame or self,
      p2 = p2,
      x = x,
      y = y
    }
  end,
  ["SetTooltipContent"] = function(self, content)
    self._tooltipContent = content
  end,
  ["EnableTooltipHover"] = function(self, flag)
    if flag == nil then flag = true end
    self._isTooltipHoverEnabled = flag
  end,
}

local attachScripts = {
  ["OnEnter"] = function(self)
    if not self._isTooltipHoverEnabled then return end

    if tooltipCancelToken then
      -- If a delay timer was already started, cancel it
      addon.Ace:CancelTimer(tooltipCancelToken)
      tooltipCancelToken = nil
    end

    -- todo: configurable delay?
    local delay = tooltipDelay

    tooltipCancelToken = addon.Ace:ScheduleTimer(function()
      addon:catch(function()
        self:ShowTooltip()
      end)
    end, delay)
  end,
  ["OnLeave"] = function(self)
    if not self._isTooltipHoverEnabled then return end

    if tooltipCancelToken then
      addon.Ace:CancelTimer(tooltipCancelToken)
      tooltipCancelToken = nil
    end

    self:HideTooltip()
  end
}

--- Sets methods and scripts on the provided frame so that when the frame is hovered over,
--- a tooltip will be displayed (content must be set first)
function addon:AttachTooltip(frame)
  assert(type(frame) == "table", "A frame must be defined when attaching a tooltip")

  for fname, fn in pairs(methods) do
    frame[fname] = fn
  end

  frame:EnableMouse(true)
  for event, fn in pairs(attachScripts) do
    frame:SetScript(event, fn)
  end

  -- By default, the tooltip is anchored to the top-right of the attached frame
  frame:SetTooltipAnchor("BOTTOMLEFT", frame, "TOPRIGHT")

  -- Tooltip-on-hover is enabled by default as soon as a tooltip is added
  frame:EnableTooltipHover(true)
end