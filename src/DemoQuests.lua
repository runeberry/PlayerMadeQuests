local _, addon = ...
addon:traceFile("DemoQuests.lua")

local dqlist = {}

addon.DemoQuests = {}

-- todo: Make id an optional property, use quest hash when possible

function addon.DemoQuests:Add(quest)
  if quest == nil or type(quest) ~= "table" then
    error("Cannot add demo quest - quest is nil or invalid")
  end

  if quest.id == nil or type(quest.id) ~= "string" or quest.id == "" then
    error("Cannot add demo quest - quest.id is nil or invalid")
  end

  if dqlist[quest.id] ~= nil then
    error("Cannot add demo quest - id '"..quest.id.."' is already taken")
  end

  dqlist[quest.id] = quest
end

function addon.DemoQuests:Get(id)
  return dqlist[id]
end

addon:onload(function()
  if addon.DemoQuestData == nil then
    addon:error("Demo quests did not load!")
    return
  end

  for _, quest in pairs(addon.DemoQuestData) do
    addon.DemoQuests:Add(quest)
  end
end)