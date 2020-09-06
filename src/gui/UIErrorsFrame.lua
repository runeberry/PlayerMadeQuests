local _, addon = ...
local frame = addon.G.UIErrorsFrame
local localizer = addon.QuestScriptLocalizer

local progressCache = {}

addon.AppEvents:Subscribe("ObjectiveUpdated", function(obj)

  local lastProgress = progressCache[obj.id]
  progressCache[obj.id] = obj.progress

  -- Only publish message for objectives with > 0 progress
  if obj.progress == 0 then return end
  -- Only publish message for objectives that have advanced forward, not back
  if lastProgress and lastProgress > obj.progress then return end

  local msg = localizer:GetDisplayText(obj, "progress")

  if obj.progress >= obj.goal then
    msg = msg.." (Complete)"
  end

  frame:AddMessage(msg, 1.0, 1.0, 0.1)
end)

addon.AppEvents:Subscribe("ObjectiveCompleted", function(obj)
  progressCache[obj.id] = nil
end)