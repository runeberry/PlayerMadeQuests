local _, addon = ...

--[[
  Quest model:
  {
    questId: "string",        -- Required, globally unique between all users (can be safely shared)
    addonVersion: 0,          -- Required, version of PMQ that the quest was compiled with
    name: "string",           -- Required
    source: "string",         -- Indicates where the quest was before the QuestLog (catalog, demo, draft)
    description: "string",    -- Flavor text shown on quest start
    completion: "string",     -- Flavor text shown when quest is Completed
    status = "string",        -- see QuestStatus.lua
    objectives: {             -- array of trackable quest objectives
      {
        name = "string",          -- name of the QuestEvent which will trigger evaluation of this objective
        displayText = {           -- variations of text that will be shown
          log = "string",             -- shown in the quest log window (light details)
          progress = "string",        -- shown when an objective is progressed (light details)
          quest = "string",           -- shown in the QuestInfoFrame (most details)
          full = "string",            -- shown for spoilers (full details)
        },
        goal = 1,                 -- number of times these conditions must be met to complete this objective (min. 1)
        conditions = {            -- map of conditions <> expected value(s) for that condition (examples shown)
          use-emote = { "val1": true },
          target = { "val2": true, "val3": true },
        }
      }
    }
  }
--]]

addon.QuestLog = addon:NewRepository("Quest", "questId")
local QuestLog = addon.QuestLog
QuestLog:SetSaveDataSource("QuestLog")
QuestLog:EnableWrite(true)
QuestLog:EnableCompression(true)
QuestLog:EnableTimestamps(true)

function QuestLog:SaveWithStatus(questOrId, status)
  assert(type(questOrId) == "table" or type(questOrId) == "string", "Failed to SaveWithStatus: quest or questId are required")
  assert(status ~= nil, "Failed to SaveWithStatus: status is required")

  local quest
  if type(questOrId) == "table" then
    quest = questOrId
  else
    quest = self:FindByID(questOrId)
    assert(quest, "Failed to SaveWithStatus: no quest exists with id "..questOrId)
  end

  assert(addon:IsValidQuestStatusChange(quest.status, status))
  quest.status = status
  self:Save(quest)
end

function QuestLog:Validate(quest)
  addon:ValidateQuestStatusChange(quest)
end

-- Need to listen for objective changes and reflect those changes in the quest log

addon.AppEvents:Subscribe("ObjectiveUpdated", function(obj)
  local quest = QuestLog:FindByID(obj.questId)
  if not quest then
    addon.Logger:Warn("Unable to update quest objective: no quest by id %s", obj.questId)
    return
  elseif quest.status ~= addon.QuestStatus.Active then
    addon.Logger:Warn("Unable to update quest objective: quest \"%s\" is not Active (%s)", quest.name, quest.status)
    return
  end

  local qobj
  for _, qo in ipairs(quest.objectives) do
    if qo.id == obj.id then
      qobj = qo
      break
    end
  end
  if not qobj then
    addon.Logger:Warn("Unable to update quest objective: no objective on quest \"%s\" with id %s", quest.name, obj.id)
    return
  end

  qobj.progress = obj.progress

  local isQuestFinished
  -- objective is considered completed if progress is >= goal
  if obj.progress >= obj.goal then
    -- quest is only considered completed if all objectives would be considered completed
    isQuestFinished = true
    for _, qo in pairs(quest.objectives) do
      if qo.progress < qo.goal then
        isQuestFinished = false
        break
      end
    end
  end

  if isQuestFinished then
    quest.status = addon.QuestStatus.Finished
  end

  QuestLog:Save(quest)
end)