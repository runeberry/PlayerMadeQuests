local _, addon = ...
local MessageEvents, MessageDistribution, MessagePriority = addon.MessageEvents, addon.MessageDistribution, addon.MessagePriority
local QuestStatus, QuestRewardStatus = addon.QuestStatus, addon.QuestRewardStatus
local IsInGroup, IsInRaid, UnitIsPlayer = addon.G.IsInGroup, addon.G.IsInRaid, addon.G.UnitIsPlayer
local GetUnitName = addon.G.GetUnitName

local playerName

local function getQuestName(questId)
  if questId then
    local quest = addon.QuestLog:FindByID(questId)
    if not quest then
      quest = addon.QuestArchive:FindByID(questId)
    end
    if quest then
      return string.format("\"%s\"", quest.name)
    end
  end

  return "the quest"
end

local function isRewardGiver(givers)
  if not givers or #givers == 0 then return false end

  for _, giver in ipairs(givers) do
    if giver == playerName then return true end
  end

  return false
end

--- Get rewards that this player is eligible to distribute
local function getEligibleRewardText(response)
  if not response.rewards then return end

  local eligible = {}

  for _, reward in ipairs(response.rewards) do
    if reward.status == QuestRewardStatus.Unclaimed and isRewardGiver(reward.givers) then
      eligible[#eligible+1] = addon.QuestRewards:GetRewardName(reward)
    end
  end

  if #eligible > 0 then
    return table.concat(eligible, ", ")
  end
end

function addon:RequestTargetQuestStatus(quest)
  if not UnitIsPlayer("target") then
    addon.Logger:Warn("You must target another player character")
    return
  end

  local targetName = GetUnitName("target")
  if targetName == playerName then
    addon.Logger:Warn("You must target another player character")
    return
  end

  local opts = { distribution = MessageDistribution.Whisper, target = targetName }
  MessageEvents:Publish("QuestStatusRequest", opts, quest.questId)
  addon.Logger:Warn("Checking %s's status for \"%s\"...", targetName, quest.name)
end

function addon:RequestPartyQuestStatus(quest)
  if not IsInGroup() then
    addon.Logger:Warn("You are not in a party")
    return
  end

  local opts = { distribution = MessageDistribution.Party }
  MessageEvents:Publish("QuestStatusRequest", opts, quest.questId)
  addon.Logger:Warn("Checking party's status for \"%s\"...", quest.name)
end

function addon:RequestRaidQuestStatus(quest)
  if not IsInRaid() then
    addon.Logger:Warn("You are not in a raid group")
    return
  end

  local opts = { distribution = MessageDistribution.Raid }
  MessageEvents:Publish("QuestStatusRequest", opts, quest.questId)
  addon.Logger:Warn("Checking raid's status for \"%s\"...", quest.name)
end

addon:OnBackendStart(function()
  playerName = addon:GetPlayerName()

  MessageEvents:Subscribe("QuestStatusRequest", function(distribution, sender, questId)
    -- A player wants to know the current status of one of your quests
    if not questId then return end

    local response = {
      status = nil,
      rewards = nil,
      requestDistribution = distribution,
    }

    local quest = addon.QuestLog:FindByID(questId) or addon.QuestArchive:FindByID(questId)
    if quest then
      response.status = quest.status
    end

    local questRewards = addon.QuestRewards:FindByQuery(function(reward)
      return reward.questId == questId
    end)
    response.rewards = questRewards

    local opts = { distribution = MessageDistribution.Whisper, target = sender, priority = MessagePriority.Bulk }
    MessageEvents:Publish("QuestStatusResponse", opts, questId, response)
  end)

  MessageEvents:Subscribe("QuestStatusResponse", function(distribution, sender, questId, response)
    -- A player has responded to your request about their quest status

    local questName = getQuestName(questId)

    local message
    if response.status == nil then
      message = string.format("%s does not have %s.", sender, questName)
    elseif response.status ~= QuestStatus.Completed then
      message = string.format("%s has not completed %s.", sender, questName)
    else
      message = string.format("%s has completed %s", sender, questName)

      local rewardText = getEligibleRewardText(response)
      if rewardText then
        message = string.format("%s and is eligible for the following rewards: %s", message, rewardText)
      else
        message = message.."."
      end
    end

    addon.Logger:Warn(message)
  end)
end)