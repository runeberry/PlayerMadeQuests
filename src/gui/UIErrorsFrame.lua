local _, addon = ...
local frame = addon.G.UIErrorsFrame
local compiler = addon.QuestScriptCompiler

addon.AppEvents:Subscribe("ObjectiveUpdated", function(obj)
  local msg = compiler:GetDisplayText(obj, "progress")

  if obj.progress >= obj.goal then
    -- todo: make quest status another %var, perhaps?
    msg = msg.." (Complete)"
  end

  frame:AddMessage(msg, 1.0, 1.0, 0.1)
end)