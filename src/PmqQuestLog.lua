local _, addon = ...
addon:traceFile("PmqQuestLog.lua")

addon.QuestStatus = {
  Invited = "Invited",
  Active = "Active",
  Failed = "Failed",
  Completed = "Completed",
  Archived = "Archived"
}
local status = addon.QuestStatus

local qlog = {
  list = {}
}

-- Clears out the quest log
function qlog:Reset()
  qlog.list = {}
  qlog:Save()
  addon.AppEvents:Publish("QuestLogLoaded", qlog)
  addon:info("Quest log reset")
end

-- Writes the quest log back to SavedVariables
function qlog:Save()
  PlayerMadeQuestsCache.QuestLog = {}
  for _, quest in pairs(qlog.list) do
    local saveQuest = {
      id = quest.id,
      name = quest.name,
      author = quest.author,
      status = quest.status,
      objectives = {}
    }
    for _, obj in pairs(quest.objectives) do
      table.insert(saveQuest.objectives, addon.QuestEngine:SerializeObjective(obj))
    end
    table.insert(PlayerMadeQuestsCache.QuestLog, saveQuest)
  end
end

function qlog:Load()
  if PlayerMadeQuestsCache.QuestLog == nil then
    return
  end

  qlog.list = {}
  for _, quest in pairs(PlayerMadeQuestsCache.QuestLog) do
    qlog:LoadQuest(quest)
  end
  addon.AppEvents:Publish("QuestLogLoaded", qlog)
  addon:trace("Quest log loaded from SavedVariables")
end

function qlog:LoadQuest(quest)
  local loadQuest = {
    id = quest.id,
    name = quest.name,
    author = quest.author,
    status = quest.status,
    objectives = {}
  }
  for _, ostr in pairs(quest.objectives) do
    local obj = addon.QuestEngine:LoadObjective(ostr);
    obj.quest = loadQuest -- give obj a ref back to its quest
    table.insert(loadQuest.objectives, obj)
  end
  qlog.list[loadQuest.id] = loadQuest
  return loadQuest
end

-- Adds a quest from the demo list
function qlog:AddQuest(id)
  local quest = addon.DemoQuests:Get(id)
  if quest == nil then
    addon:error("No demo quest exists with id -", id)
    return
  end

  local existingQuest = qlog:GetQuest(id)
  if existingQuest then
    addon:error("You're already on that quest! (", existingQuest.name, "-", existingQuest.status, ")")
    return
  end

  local loadedQuest = qlog:LoadQuest(quest) -- Load quest from demo list into memory
  loadedQuest.status = status.Active
  qlog:Save() -- Then save it back to file
  addon.AppEvents:Publish("QuestAccepted", loadedQuest)
end

function qlog:GetQuest(id)
  for i, q in pairs(qlog.list) do
    if id == i then
      return q
    end
  end

  return nil
end

function qlog:TryCompleteQuest(id)
  local quest = qlog:GetQuest(id)
  if quest and quest.status == status.Active then
    for _, obj in pairs(quest.objectives) do
      if obj.progress < obj.goal then
        -- If any objective is not complete, then the quest is not complete
        return
      end
    end

    quest.status = status.Completed
    qlog:Save()
    addon.AppEvents:Publish("QuestStatusChanged", quest)
  end
end

addon.qlog = qlog