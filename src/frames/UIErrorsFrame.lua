local _, addon = ...
local frame = addon.G.UIErrorsFrame

addon.AppEvents:Subscribe("ObjectiveUpdated", function(obj)
  local msg = obj:GetDisplayText()
  msg = msg.." "..obj.progress.."/"..obj.goal

  if obj.progress >= obj.goal then
    msg = msg.." (Complete)"
  end

  frame:AddMessage(msg, 1.0, 1.0, 0.1)
end)