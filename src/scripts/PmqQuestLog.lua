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
}

local function isObjectiveComplete(objective)
  return objective.progress >= objective.goal
end

local function isQuestComplete(quest)
  for _, obj in pairs(quest.objectives) do
    if isObjectiveComplete(obj) == false then
      -- At least one objective is not complete
      return false
    end
  end

  return true
end

-- Clears out the quest log
function qlog:Reset()
  qlog.list = {}
  qlog:Save()
  addon:info("Quest log reset")
end

-- Writes the quest log back to saved variables
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
      table.insert(saveQuest.objectives, addon.rules:SerializeObjective(obj))
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
    local obj = addon.rules:LoadObjective(ostr);
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

  -- For demo purposes, show that the quest was accepted
  addon:info("Accepted quest:")
  qlog:PrintQuest(id)
end

function qlog:GetQuest(id)
  for i, q in pairs(qlog.list) do
    if id == i then
      return q
    end
  end

  return nil
end

function qlog:PrintQuests()
  local numQuests = addon:tlen(qlog.list)
  addon:info("You have", numQuests, addon:pluralize(numQuests, "quest"),"in your log.")

  for i, q in pairs(qlog.list) do
    qlog:PrintQuest(i)
  end
end

function qlog:PrintQuest(id)
  local q = qlog:GetQuest(id)
  addon:info(q.name, "(", q.status, ")")

  if q.status == status.Active then
    for _, o in pairs(q.objectives) do
      -- todo: pair this language up with the objective type itself
      local marker = "  [ ]"
      if o.progress == o.goal then
        marker = "  [X]" -- mark the objective complete
      end
      addon:info(marker, o.rule.name, o.unitName, o.progress, "of", o.goal)
    end
  end
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
    addon:info(quest.name, "- Quest Complete!")
  end
end

addon.qlog = qlog