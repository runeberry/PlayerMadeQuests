local _, addon = ...

addon.QuestScriptLocalizer = {}

-- Valid values for scope are: log [default], progress, quest, full
-- Use this method at runtime
-- todo: remove this function and the localizer altogether
function addon.QuestScriptLocalizer:GetDisplayText(obj, scope)
  return addon:GetCheckpointDisplayText(obj, scope)
end