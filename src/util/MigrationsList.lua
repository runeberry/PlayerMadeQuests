local _, addon = ...

addon:NewQuestMigration(200, function(quest)
  local t = addon.QuestScriptTokens
  if quest.objectives then
    for _, obj in pairs(quest.objectives) do
      if obj.displaytext then
        -- displaytext was moved from the top level to a new parameters table
        obj.parameters = { [t.PARAM_TEXT] = obj.displaytext }
        obj.displaytext = nil
      end
    end
  end
  if quest.start then
    quest.start.parameters = { [t.PARAM_TEXT] = quest.start.displaytext }
    quest.start.displaytext = nil
  end
  if quest.complete then
    quest.complete.parameters = { [t.PARAM_TEXT] = quest.complete.displaytext }
    quest.complete.displaytext = nil
  end
end)