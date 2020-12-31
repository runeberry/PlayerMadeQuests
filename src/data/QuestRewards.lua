local _, addon = ...
local GetCoinTextureString = addon.G.GetCoinTextureString

addon.QuestRewards = addon:NewRepository("Reward", "rewardId")
addon.QuestRewards:SetSaveDataSource("QuestRewards")
addon.QuestRewards:EnableWrite(true)
addon.QuestRewards:EnableCompression(true)
addon.QuestRewards:EnableTimestamps(true)

addon.QuestRewardStatus = {
  Unclaimed = "Unclaimed",
  MailSent = "MailSent",
  MailReceived = "MailReceived",
  Traded = "Traded",
  Claimed = "Claimed",
}
local status = addon.QuestRewardStatus

local claimedStatuses = {
  [status.MailReceived] = true,
  [status.Traded] = true,
  [status.Claimed] = true,
}

local function buildRewardId(quest, identifier)
  return string.format("reward-%s-%s", quest.questId, tostring(identifier))
end

local function getRewardGivers(quest)
  local givers = {}
  for playerName in pairs(quest.rewards.parameters.player) do
    -- map from DistinctSet to simple array of names
    givers[#givers+1] = addon:PopulateText(playerName, quest)
  end
  return givers
end

local function buildItemReward(quest, itemId, quantity)
  -- Assuming that the full info is available now
  -- since it was displayed in the QuestInfoFrame
  local item = addon:LookupItem(itemId)

  return {
    rewardId = buildRewardId(quest, itemId),
    questId = quest.questId,
    status = status.Unclaimed,
    givers = getRewardGivers(quest),
    itemId = itemId,
    itemName = item.name,
    itemLink = item.link,
    itemQuantity = quantity,
  }
end

local function buildMoneyReward(quest, money)
  return {
    rewardId = buildRewardId(quest, "money"),
    questId = quest.questId,
    status = status.Unclaimed,
    givers = getRewardGivers(quest),
    money = money,
  }
end

local function saveReward(self, reward, force)
  -- Unless force is enabled, don't overwrite existing reward entries
  if not force and self:FindByID(reward.rewardId) then return end
  self:Save(reward)
end

function addon.QuestRewards:FindClaimedRewards()
  return self:FindByQuery(function(reward)
    return reward.status and claimedStatuses[reward.status]
  end)
end

function addon.QuestRewards:SaveQuestRewards(quest, force)
  if not quest.rewards or not quest.rewards.parameters or not quest.rewards.parameters.player then return end

  local rewards = {}

  if quest.rewards.parameters.rewarditem then
    if quest.rewards.parameters.choose then
      if quest.rewards.selectedIndex then
        -- One item is rewarded as chosen by the player
        local item = quest.rewards.parameters.rewarditem[quest.rewards.selectedIndex]
        if item then
          rewards[#rewards+1] = buildItemReward(quest, item.itemId, item.quantity)
        end
        -- Else an invalid selection was made (somehow?)
      else
        -- One item is rewarded, but no selection was made (somehow?)
      end
    else
      -- All items are rewarded to the player
      for _, item in ipairs(quest.rewards.parameters.rewarditem) do
        rewards[#rewards+1] = buildItemReward(quest, item.itemId, item.quantity)
      end
    end
  end

  if quest.rewards.parameters.rewardmoney and quest.rewards.parameters.rewardmoney > 0 then
    rewards[#rewards+1] = buildMoneyReward(quest, quest.rewards.parameters.rewardmoney)
  end

  for _, reward in ipairs(rewards) do
    saveReward(self, reward, force)
  end
end

--- Gets a UI-friendly name for the provided quest reward
function addon.QuestRewards:GetRewardName(reward)
  local rewardText = "???"

  if reward.itemId then
    rewardText = reward.itemLink or reward.itemName
    if not rewardText then
      -- If the item link/name are somehow unavailable, try looking up the item now
      local item = addon:LookupItem(reward.itemId)
      if item then
        rewardText = item.link or item.name
      end
      if not rewardText then
        rewardText = string.format("(Item #%i)", reward.itemId)
      end
    end

    if reward.itemQuantity and reward.itemQuantity > 0 then
      rewardText = string.format("%ix %s", reward.itemQuantity, rewardText)
    end
  elseif reward.money then
    rewardText = GetCoinTextureString(reward.money)
  end

  return rewardText
end

addon.AppEvents:Subscribe("QuestCompleted", function(quest)
  addon.QuestRewards:SaveQuestRewards(quest)
end)