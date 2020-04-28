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

-- Gets only the fields that will be written to SavedVariables
local function getSaveObjective(obj)
  local toSave = {
    name = obj.name,
    progress = obj.progress,
    goal = obj.goal,
    args = obj.args
  }

  return toSave
end

-- Gets only the fields that will be written to SavedVariables
local function getSaveQuest(quest)
  local toSave = {
    id = quest.id,
    name = quest.name,
    level = quest.level,
    status = quest.status,
    objectives = {}
  }

  for _, obj in pairs(quest.objectives) do
    table.insert(toSave.objectives, getSaveObjective(obj))
  end

  return toSave
end

-- Hooks up an objective from SavedVariables with all required fields
local function loadSavedObjective(saved)
  local obj = addon.QuestEngine:CreateObjective(saved.name, saved.goal, unpack(saved.args))
  obj.progress = saved.progress
  return obj
end

-- Hooks up a quest from SavedVariables with all required fields
local function loadSavedQuest(saved)
  local quest = {
    id = saved.id,
    name = saved.name,
    level = saved.level,
    status = saved.status,
    objectives = {}
  }

  for _, savedObj in pairs(saved.objectives) do
    local obj = loadSavedObjective(savedObj)
    obj.quest = quest
    table.insert(quest.objectives, obj)
  end

  return quest
end

local function loadDemoObjective(str)
  local obj = addon:strWords(str)

  if #obj == 0 then
    error("Unable to parse empty objective string.")
  end

  local ruleName
  local goal = 1 -- Default goal is 1 if no goal is specified
  local args = {}

  for i, word in pairs(obj) do
    if i == 1 then
      -- First word is always the rule of the objective
      ruleName = word
    elseif i == 2 and word:match("%[%d+%]") then
      -- Second word may be the goal, if the format is "[#]"
      goal = tonumber(word:match("%d+"))
    else
      -- All other remaining words are the objective's args
      table.insert(args, word)
    end
  end

  return addon.QuestEngine:CreateObjective(ruleName, goal, unpack(args))
end

local function loadDemoQuest(demo)
  local quest = {
    id = demo.id,
    name = demo.name,
    level = demo.level,
    objectives = {}
  }

  for _, demoObj in pairs(demo.objectives) do
    local obj = loadDemoObjective(demoObj)
    obj.quest = quest
    table.insert(quest.objectives, obj)
  end

  return quest
end

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
    local toSave = getSaveQuest(quest)
    table.insert(PlayerMadeQuestsCache.QuestLog, addon.Ace:Serialize(toSave))
  end
  addon.AppEvents:Publish("QuestLogSaved", qlog)
end

function qlog:Load()
  if PlayerMadeQuestsCache.QuestLog == nil then
    return
  end

  qlog.list = {}
  for _, serialized in pairs(PlayerMadeQuestsCache.QuestLog) do
    local ok, saved = addon.Ace:Deserialize(serialized)
    if ok then
      local quest = loadSavedQuest(saved)
      table.insert(qlog.list, quest)
    else
      error("Error deserializing quest: "..saved)
    end
  end
  addon.AppEvents:Publish("QuestLogLoaded", qlog)
end

-- Adds a quest from the demo list
function qlog:AddQuest(id)
  local demo = addon.DemoQuests:Get(id)
  if demo == nil then
    addon:error("No demo quest exists with id -", id)
    return
  end

  local existingQuest = qlog:GetQuest(id)
  if existingQuest then
    addon:error("You're already on that quest! (", existingQuest.name, "-", existingQuest.status, ")")
    return
  end

  local quest = loadDemoQuest(demo)
  quest.status = status.Active
  table.insert(qlog.list, quest)
  qlog:Save() -- Then save it back to file
  addon.AppEvents:Publish("QuestAccepted", quest)
end

function qlog:GetQuest(id)
  for _, q in pairs(qlog.list) do
    if q.id == id then
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