local _, addon = ...
local QuestEngine = addon.QuestEngine
local QuestLog, QuestStatus = addon.QuestLog, addon.QuestStatus
local QuestCatalog, QuestCatalogStatus = addon.QuestCatalog, addon.QuestCatalogStatus
local QuestArchive = addon.QuestArchive

--[[
  QuestActions are complex actions that users may perform on quests.
  The code in QuestActions should only concern the following things:
    * Updating any data entities
    * Whether to show or suppress StaticPopups
    * QuestEngine tracking
    * Printing chat feedback for the player
  Any other side-effects of these actions should be handled elsewhere
  by subscribing to the AppEvents published here.
--]]

local function startQuest(quest)
  -- If this quest is already in the quest log...
  local existingQuest = QuestLog:FindByID(quest.questId)
  if existingQuest then
    -- Need to ensure that this quest is not being tracked before starting tracking again
    QuestEngine:StopTracking(existingQuest)
  end

  -- Clean quest progress on fresh accept, just in case
  if quest.objectives then
    for _, obj in pairs(quest.objectives) do
      obj.progress = 0
    end
  end

  QuestLog:SaveWithStatus(quest, QuestStatus.Active)
  QuestEngine:StartTracking(quest)

  local catalogItem = QuestCatalog:FindByID(quest.questId)
  if catalogItem and catalogItem.status ~= QuestCatalogStatus.Accepted then
    QuestCatalog:SaveWithStatus(catalogItem, QuestCatalogStatus.Accepted)
  end

  -- A quest is no longer archived once it becomes active
  local archivedQuest = QuestArchive:FindByID(quest.questId)
  if archivedQuest then
    QuestArchive:Delete(archivedQuest)
  end
end

--------------------
-- Public methods --
--------------------

function addon:AcceptQuest(quest, suppressPopup)
  if not QuestEngine:EvaluateRequirements(quest) then
    addon.Logger:Warn("You do not meet the requirements to start this quest.")
    return
  end
  if not QuestEngine:EvaluateStart(quest) then
    addon.Logger:Warn("Unable to accept quest: start conditions are not met")
    return
  end
  if not QuestEngine:EvaluateRecommendations(quest) and not suppressPopup then
    addon.StaticPopups:Show("StartQuestBelowRequirements", quest)
    return
  end

  startQuest(quest)
  addon.Logger:Warn("Quest Accepted: %s", quest.name)
  addon.AppEvents:Publish("QuestAccepted", quest)
end

function addon:DeclineQuest(quest)
  local catalogItem = QuestCatalog:FindByID(quest.questId)
  if catalogItem and catalogItem.status ~= QuestCatalogStatus.Declined then
    QuestCatalog:SaveWithStatus(catalogItem, QuestCatalogStatus.Declined)
  end
  addon.AppEvents:Publish("QuestDeclined", quest)
end

function addon:AbandonQuest(quest, suppressPopup)
  if not suppressPopup then
    addon.StaticPopups:Show("AbandonQuest", quest)
    return
  end

  QuestLog:SaveWithStatus(quest, QuestStatus.Abandoned)
  QuestEngine:StopTracking(quest)
  addon.Logger:Warn("Quest abandoned: %s", quest.name)
  addon.AppEvents:Publish("QuestAbandoned", quest)
end

function addon:CompleteQuest(quest)
  if not QuestEngine:EvaluateComplete(quest) then
    addon.Logger:Warn("Unable to complete quest: completion conditions are not met")
    return
  end

  QuestLog:SaveWithStatus(quest, QuestStatus.Completed)
  QuestEngine:StopTracking(quest)
  addon.Logger:Warn("%s completed.", quest.name)
  addon.AppEvents:Publish("QuestCompleted", quest)
end

function addon:RestartQuest(quest, suppressPopup)
  if not suppressPopup then
    addon.StaticPopups:Show("RestartQuest", quest)
    return
  end

  startQuest(quest)
  addon.Logger:Warn("Quest Restarted: %s", quest.name)
  addon.AppEvents:Publish("QuestRestarted", quest)
end