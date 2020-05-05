local _, addon = ...
addon:traceFile("QuestLog.lua")

-- In-memory quest log
local qlog = {}

addon.QuestLog = {}
addon.QuestLogStatus = {
  Active = "Active",
  Failed = "Failed",
  Completed = "Completed",
}
local status = addon.QuestLogStatus

local function toSaveFormat(quest)
  local questToSave = {
    name = quest.name,
    description = quest.description,
    status = quest.status,
    objectives = {}
  }

  for _, obj in pairs(quest.objectives) do
    local objToSave = {
      name = obj.name,
      displayText = obj.displayText,
      progress = obj.progress,
      goal = obj.goal,
      metadata = obj.metadata,
      conditions = obj.conditions -- No translation
    }

    table.insert(questToSave.objectives, objToSave)
  end

  return questToSave
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

function addon.QuestLog:AcceptFromDemo(demo)
  local compiled = addon.QuestScript:Compile(demo.script)
  self:AcceptFromCatalog(compiled)
end

function addon.QuestLog:AcceptFromCatalog(listing)
  addon.QuestEngine:ActivateQuest(listing)
  listing.status = status.Active
  table.insert(qlog, listing)
  self:Save()
end

function addon.QuestLog:Save()
  local toSaveList = {}
  for _, quest in pairs(qlog) do
    table.insert(toSaveList, toSaveFormat(quest))
  end
  local serialized = addon.Ace:Serialize(toSaveList)
  local compressed = addon.LibCompress:CompressHuffman(serialized)
  addon.SaveData:Save("QuestLog", compressed)
  addon.AppEvents:Publish("QuestLogSaved", qlog)
  addon:debug("Quest log saved")
end

function addon.QuestLog:Load()
  local compressed = addon.SaveData:LoadString("QuestLog")
  -- For some reason the data becomes an empty table when I first access it?
  if compressed == "" then
    addon:debug("No QuestLog save data available")
    return
  end

  local serialized, msg = addon.LibCompress:Decompress(compressed)
  if serialized == nil then
    error("Error decompressing quest log: "..msg)
  end

  local ok, saved = addon.Ace:Deserialize(serialized)
  if not(ok) then
    -- 2nd param is an error message if it failed
    error("Error deserializing quest: "..qlog)
  end

  qlog = saved
  for _, q in pairs(qlog) do
    if q.status == status.Active then
      addon.QuestEngine:ActivateQuest(q)
    end
  end

  addon.AppEvents:Publish("QuestLogLoaded", qlog)
  addon:info("Quest log loaded")
end

function addon.QuestLog:Reset()
  qlog = {}
  self:Save()
  addon.AppEvents:Publish("QuestLogLoaded", qlog)
  addon:info("Quest log reset")
end

function addon.QuestLog:SetStatus(quest, stat)
  quest.status = stat
  self:Save()
  addon.AppEvents:Publish("QuestStatusChanged", quest) --todo: still necessary?
end

function addon.QuestLog:Get()
  return qlog
end

function addon.QuestLog:Print()
  -- addon:logtable(qlog)
  addon:info("=== You have", addon:tlen(qlog), "quests in your log ===")
  for _, q in pairs(qlog) do
    addon:info(q.name, "(", q.status, ") [", q.id, "]")
    for _, o in pairs(q.objectives) do
      addon:info("    ", o.name, o.progress, "/",  o.goal)
    end
  end
end

addon:onload(function()
  addon.QuestLog:Load()
  addon.AppEvents:Subscribe("QuestCompleted", function(quest)
    addon.QuestLog:SetStatus(quest, status.Completed)
  end)
end)