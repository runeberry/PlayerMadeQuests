local _, addon = ...

addon.QuestRewards = addon:NewRepository("Reward", "questId")
addon.QuestRewards:SetSaveDataSource("QuestRewards")
addon.QuestRewards:EnableWrite(true)
addon.QuestRewards:EnableCompression(true)
addon.QuestRewards:EnableTimestamps(true)

function addon.QuestRewards:SaveQuestRewards(quest, choice, claimed)
  if not quest.rewards or not quest.rewards.parameters then return end

  local players = {}
  for playerName in pairs(quest.rewards.parameters.player) do
    -- map from DistinctSet to simple array of names
    players[#players+1] = playerName
  end

  local items
  if quest.rewards.parameters.rewarditem then
    items = addon:CopyTable(quest.rewards.parameters.rewarditem)
  end

  local reward = {
    questId = quest.questId,
    questName = quest.name,
    players = players,
    items = items,
    money = quest.rewards.parameters.rewardmoney,

    choice = choice,
    claimed = claimed or false,
  }

  self:Save(reward)
end

addon.AppEvents:Subscribe("QuestCompleted", function(quest)
  if not addon.QuestRewards:FindByID(quest.questId) then
    -- Save quest rewards, but don't overwrite existing rewards info
    -- (in case the quest is being replayed)
    addon.QuestRewards:SaveQuestRewards(quest)
  end
end)