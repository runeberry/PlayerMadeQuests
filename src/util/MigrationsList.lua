local _, addon = ...

addon:NewMigration(200, function()
  local t = addon.QuestScriptTokens

  local migrateDisplayText = function(qs)
    for _, q in ipairs(qs) do
      if q.objectives then
        for _, obj in pairs(q.objectives) do
          if obj.displaytext then
            -- displaytext was moved from the top level to a new parameters table
            obj.parameters = { [t.PARAM_TEXT] = obj.displaytext }
            obj.displaytext = nil
          end
        end
      end
      if q.start then
        q.start.parameters = { [t.PARAM_TEXT] = q.start.displaytext }
        q.start.displaytext = nil
      end
      if q.complete then
        q.complete.parameters = { [t.PARAM_TEXT] = q.complete.displaytext }
        q.complete.displaytext = nil
      end
    end
  end

  local quests = addon.QuestLog:FindAll()
  migrateDisplayText(quests)
  for _, quest in ipairs(quests) do
    addon.QuestLog:Save(quest)
  end

  quests = addon.QuestArchive:FindAll()
  migrateDisplayText(quests)
  for _, quest in ipairs(quests) do
    addon.QuestArchive:Save(quest)
  end
end)