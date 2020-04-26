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

local demoQuests = {
  dq1 = {
    id = "dq1",
    name = "Babby's First Quest",
    author = "Nekrage-Grobbulus",
    objectives = {
      "TargetMob,0,5,Cow",
      "KillMob,0,2,Mangy Wolf",
      "KillMob,0,3,Chicken"
    }
  },
  dq2 = {
    id = "dq2",
    name = "STONKS",
    author = "Nekrage-Grobbulus",
    objectives = {
      "KillMob,0,3,Defias Prisoner",
      "KillMob,0,3,Defias Inmate",
      "KillMob,0,3,Defias Captive"
    }
  },
  dq3 = {
    id = "dq3",
    name = "Grob Has a Queue",
    author = "Midna-Kirtonos",
    objectives = {
      "KillMob,0,2,Bloodtalon Scythemaw",
      "KillMob,0,3,Elder Mottled Boar",
      "TargetMob,0,5,Venomtail Scorpid"
    }
  },
  dq4 = {
    id = "dq4",
    name = "More Blood for de Blood God",
    author = "Midna-Kirtonos",
    objectives = {
      "KillMob,0,3,Bloodscalp Axe Thrower",
      "KillMob,0,2,Bloodscalp Shaman",
      "TargetMob,0,5,Black Kingsnake"
    }
  },
  dq5 = {
    id = "dq5",
    name = "Killing Stuff is Hard",
    author = "Midna-Kirtonos",
    objectives = {
      "TargetMob,0,3,Bloodtalon Scythemaw",
      "TargetMob,0,3,Elder Mottled Boar",
      "TargetMob,0,3,Venomtail Scorpid"
    }
  },
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
      table.insert(saveQuest.objectives, addon.Rules:SerializeObjective(obj))
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
    local obj = addon.Rules:LoadObjective(ostr);
    obj.quest = loadQuest -- give obj a ref back to its quest
    table.insert(loadQuest.objectives, obj)
  end
  qlog.list[loadQuest.id] = loadQuest
  return loadQuest
end

-- Adds a quest from the demo list
function qlog:AddQuest(id)
  local quest = demoQuests[id]
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