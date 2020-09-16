local _, addon = ...
local QuestEngine = addon.QuestEngine
local QuestLog, QuestStatus = addon.QuestLog, addon.QuestStatus
local QuestCatalog, QuestCatalogStatus = addon.QuestCatalog, addon.QuestCatalogStatus
local QuestArchive = addon.QuestArchive

--[[
  QuestActions are complex actions that users may perform on quests.
  The code in QuestActions should only concern the following things:
    * Updating any data entities
    * StaticPopups (may move this later)
    * Printing chat feedback for the player
  Any other side-effects of these actions should be handled elsewhere
  by subscribing to the AppEvents published here.
--]]

local function startQuest(quest)
  -- Clean quest progress on fresh accept, just in case
  if quest.objectives then
    for _, obj in pairs(quest.objectives) do
      obj.progress = 0
    end
  end

  QuestLog:SaveWithStatus(quest, QuestStatus.Active)

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

local function acceptQuest(quest)
  startQuest(quest)
  addon.Logger:Warn("Quest Accepted: %s", quest.name)
  addon.AppEvents:Publish("QuestAccepted", quest)
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
  if catalogItem and catalogItem.status ~= QuestCatalogStatus.Declined then
    QuestCatalog:SaveWithStatus(catalogItem, QuestCatalogStatus.Declined)
  end
  addon.AppEvents:Publish("QuestDeclined", quest)
end

function addon:AbandonQuest(quest)
  addon.StaticPopups:Show("AbandonQuest", quest):OnYes(function()
    QuestLog:SaveWithStatus(quest, QuestStatus.Abandoned)
    addon.Logger:Warn("Quest abandoned: %s", quest.name)
    addon.AppEvents:Publish("QuestAbandoned", quest)
  end)
end

function addon:CompleteQuest(quest)
  if not QuestEngine:EvaluateComplete(quest) then
    addon.Logger:Warn("Unable to complete quest: completion conditions are not met")
    return
  end
  QuestLog:SaveWithStatus(quest, QuestStatus.Completed)
  addon.Logger:Warn("%s completed.", quest.name)
  addon.AppEvents:Publish("QuestCompleted")
end

function addon:RestartQuest(quest)
  addon.StaticPopups:Show("RestartQuest", quest):OnYes(function()
    startQuest(quest)
    addon.Logger:Warn("Quest Restarted: %s", quest.name)
    addon.AppEvents:Publish("QuestRestarted", quest)
  end)
end