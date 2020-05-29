local _, addon = ...
local Ace, LibCompress = addon.Ace, addon.LibCompress
local QuestEngine, QuestStatus = addon.QuestEngine, addon.QuestStatus
local logger = addon.Logger:NewLogger("QuestLog")

addon.QuestLog = {}

local quests = {}

addon:OnSaveDataLoaded(function()
  addon.QuestLog:Load()
end)

function addon.QuestLog:Save()
  local cleaned = addon:CleanTable(addon:CopyTable(quests))
  local serialized = Ace:Serialize(cleaned)
  local compressed = LibCompress:CompressHuffman(serialized)
  addon.SaveData:Save("QuestLog", compressed)
end

function addon.QuestLog:Load()
  local compressed = addon.SaveData:LoadString("QuestLog")
  if compressed == "" then
    -- Nothing to load
    return
  end

  local serialized, msg = LibCompress:Decompress(compressed)
  if serialized == nil then
    error("Error loading quest log: "..msg)
  end

  local ok, saved = Ace:Deserialize(serialized)
  if not(ok) then
    -- 2nd param is an error message if it failed
    error("Error loading quest log: "..saved)
  end

  for _, q in pairs(saved) do
    local qc = QuestEngine:Build(q)
    if qc.status == QuestStatus.Active then
      QuestEngine:StartTracking(qc)
    end
    quests[qc.id] = qc
  end

  addon.AppEvents:Publish("QuestLogLoaded", quests)
end

function addon.QuestLog:Clear()
  for _, quest in pairs(quests) do
    QuestEngine:StopTracking(quest)
  end
  quests = {}
  self:Save()
  addon.AppEvents:Publish("QuestLogLoaded", quests)
  logger:Info("Quest Log reset")
  addon:PlaySound("QuestAbandoned")
end

function addon.QuestLog:Print()
  logger:Info("=== You have", addon:tlen(quests), "quests in your log ===")
  for _, q in pairs(quests) do
    logger:Info(q.name, "(", q.status, ") [", q.id, "]")
    for _, o in pairs(q.objectives) do
      logger:Info("    ", o.name, o.progress, "/",  o.goal)
    end
  end
end

-- This expects a fully compiled and built quest
function addon.QuestLog:AcceptQuest(quest)
  table.insert(quests, quest)
  QuestEngine:StartTracking(quest)
  addon.QuestLog:Save()
  addon.AppEvents:Publish("QuestAccepted", quest)
  logger:Info("Accepted quest:", quest.name)
  addon:PlaySound("QuestAccepted")
  addon:ShowQuestLog(true)
end
