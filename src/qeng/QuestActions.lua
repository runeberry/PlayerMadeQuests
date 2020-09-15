local _, addon = ...
local QuestEngine = addon.QuestEngine
local QuestLog, QuestStatus = addon.QuestLog, addon.QuestStatus
local QuestCatalog, QuestCatalogStatus, QuestCatalogSource = addon.QuestCatalog, addon.QuestCatalogStatus, addon.QuestCatalogSource
local MessageEvents, MessageDistribution = addon.MessageEvents, addon.MessageDistribution

local function notifySender(catalogItem, event)
  local sender = catalogItem.from and catalogItem.from.name
  if sender and catalogItem.from.source == QuestCatalogSource.Shared then
    MessageEvents:Publish(event, { distribution = MessageDistribution.Whisper, target = sender }, catalogItem.questId)
  end
end

local function acceptQuest(quest)
  QuestLog:SaveWithStatus(quest, QuestStatus.Active)

  local catalogItem = QuestCatalog:FindByID(quest.questId)
  if catalogItem then
    QuestCatalog:SaveWithStatus(catalogItem, QuestCatalogStatus.Accepted)
    notifySender(catalogItem, "QuestInviteAccepted")
  end

  -- todo: Should probably move this so it responds to a QuestAccepted app event
  addon:PlaySound("QuestAccepted")
  addon:ShowQuestInfoFrame(false)
  addon.QuestLogFrame:Show()
  addon.Logger:Warn("Quest Accepted: %s", quest.name)
end

--------------------
-- Public methods --
--------------------

function addon:AcceptQuest(quest)
  if not QuestEngine:EvaluateRequirements(quest) then
    addon.Logger:Warn("You do not meet the requirements to start this quest.")
    return
  end
  if not QuestEngine:EvaluateStart(quest) then
    addon.Logger:Warn("Unable to accept quest: start conditions are not met")
    return
  end
  if QuestEngine:EvaluateRecommendations(quest) then
    acceptQuest(quest)
  else
    addon.StaticPopups:Show("StartQuestBelowRequirements"):OnYes(function()
      acceptQuest(quest)
    end)
  end
end

function addon:DeclineQuest(quest)
  local catalogItem = QuestCatalog:FindByID(quest.questId)
  if catalogItem then
    QuestCatalog:SaveWithStatus(catalogItem, QuestCatalogStatus.Declined)
    notifySender(catalogItem, "QuestInviteDeclined")
  end
  addon:ShowQuestInfoFrame(false)
end

function addon:AbandonQuest(quest)
  addon.StaticPopups:Show("AbandonQuest", quest):OnYes(function()
    addon:ShowQuestInfoFrame(false)
  end)
end

function addon:CompleteQuest(quest)
  if not QuestEngine:EvaluateComplete(quest) then
    addon.Logger:Warn("Unable to complete quest: completion conditions are not met")
    return
  end
  QuestLog:SaveWithStatus(quest, QuestStatus.Completed)
  addon:PlaySound("QuestComplete")
  addon:ShowQuestInfoFrame(false)
  addon.Logger:Warn("%s completed.", quest.name)
end

function addon:RetryQuest(quest)
  addon.StaticPopups:Show("RetryQuest", quest):OnYes(function()
    addon:ShowQuestInfoFrame(false)
  end)
end