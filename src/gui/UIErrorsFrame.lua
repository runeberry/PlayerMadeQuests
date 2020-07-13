local _, addon = ...
local frame = addon.G.UIErrorsFrame
local localizer = addon.QuestScriptLocalizer

addon.AppEvents:Subscribe("ObjectiveUpdated", function(obj)
  local msg = localizer:GetDisplayText(obj, "progress")

  if obj.progress >= obj.goal then
    msg = msg.." (Complete)"
  end

  frame:AddMessage(msg, 1.0, 1.0, 0.1)
end)