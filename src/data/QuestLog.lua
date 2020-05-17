local _, addon = ...
local Ace, LibCompress, PlaySoundFile = addon.Ace, addon.LibCompress, addon.G.PlaySoundFile
local QuestEngine, QuestStatus = addon.QuestEngine, addon.QuestStatus
local QuestDemos = addon.QuestDemos
local logger = addon.Logger:NewLogger("QuestLog")

addon.QuestLog = {}

local quests = {}

addon:OnSaveDataLoaded(function()
  addon.QuestLog:Load()
end)

local function acceptQuest(quest)
  table.insert(quests, quest)
  QuestEngine:StartTracking(quest)
  addon.QuestLog:Save()
  addon.AppEvents:Publish("QuestAccepted", quest)
  logger:Info("Accepted quest:", quest.name)
end

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

function addon.QuestLog:AcceptDemo(demoId)
  local demo = QuestDemos:GetDemoByID(demoId)
  if not demo then
    logger:Error("Failed to accept quest: no demo exists with id:", demoId)
    return
  end
  local parameters = QuestEngine:Compile(demo.script)
  local quest = QuestEngine:Build(parameters)
  acceptQuest(quest)
end

function addon.QuestLog:AcceptDraft(draft)
  local parameters = QuestEngine:Compile(draft.script)
  local quest = QuestEngine:Build(parameters)
  acceptQuest(quest)
end

function addon.QuestLog:AcceptListing(listing)
  local quest = QuestEngine:Build(listing.parameters)
  acceptQuest(quest)
end