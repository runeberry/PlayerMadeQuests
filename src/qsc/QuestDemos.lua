local _, addon = ...
addon:traceFile("QuestDemos.lua")

addon.QuestDemos = {}

function addon.QuestDemos:FindAll()
  return addon.DemoQuestDB
end

function addon.QuestDemos:FindByID(id)
  for _, demo in pairs(addon.DemoQuestDB) do
    if demo.id == id then return demo end
  end
end