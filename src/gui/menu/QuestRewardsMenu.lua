local _, addon = ...
local QuestRewards = addon.QuestRewards
local QuestLog, QuestArchive = addon.QuestLog, addon.QuestArchive
local StaticPopups = addon.StaticPopups
local CreateFrame = addon.G.CreateFrame

local questRewardRows = {}

local menu = addon.MainMenu:NewMenuScreen("QuestRewardsMenu")

local options = {
  colInfo = {
    {
      name = "Quest",
      width = { flexSize = 2, min = 80 },
      align = "LEFT",

    },
    {
      name = "Reward Giver",
      width = { flexSize = 2, min = 40 },
      align = "RIGHT",
    },
    {
      name = "Claimed?",
      width = { flexSize = 1, min = 40 },
      align = "CENTER"
    },
  },
  dataSource = function()
    questRewardRows = {}
    local rewards = QuestRewards:FindAll()
    table.sort(rewards, function(a, b) return a.questId < b.questId end)
    for _, reward in ipairs(rewards) do
      local players = ""
      if #reward.players == 1 then
        players = reward.players[1]
      elseif #reward.players > 1 then
        players = string.format("%s (+%i more)", reward.players[1], #reward.players - 1)
      end

      local status = ""
      if reward.claimed then
        status = addon:Colorize("green", "Yes")
      else
        status = addon:Colorize("red", "No")
      end

      local row = { reward.questName, players, status, reward.questId }
      questRewardRows[#questRewardRows+1] = row
    end
    return questRewardRows
  end,
  buttons = {
    {
      text = "View Quest Info",
      anchor = "TOP",
      enabled = "Row",
      handler = function(reward, dataTable)
        local quest = QuestLog:FindByID(reward.questId)
        if not quest then
          quest = QuestArchive:FindByID(reward.questId)
          if not quest then
            addon.Logger:Warn("Unable to show quest info: quest is no longer available in log or archive")
            return
          end
        end
        addon.QuestInfoFrame:ShowQuest(quest, "TerminatedQuest")
        dataTable:ClearSelection()
      end,
    },
    {
      text = "Notify Giver",
      anchor = "TOP",
      enabled = "Row",
      handler = function(reward, dataTable)
        -- todo: add this
        addon.Logger:Warn("Function not yet implemented")
      end,
    },
    {
      text = "Toggle Claimed",
      anchor = "TOP",
      enabled = "Row",
      handler = function(reward, dataTable)
        if reward.claimed then
          reward.claimed = false
        else
          reward.claimed = true
        end
        QuestRewards:Save(reward)
      end,
    },
    {
      text = "Clear All",
      anchor = "BOTTOM",
      enabled = "Always",
      handler = function()
        StaticPopups:Show("ResetRewards")
      end,
    },
    {
      text = "Delete",
      anchor = "BOTTOM",
      enabled = "Row",
      handler = function(reward)
        StaticPopups:Show("DeleteReward", reward)
      end,
    }
  }
}

function menu:Create(frame)
  local textinfo = {
    static = true,
    styles = addon.DefaultArticleTextStyle,
    text = {
      {
        style = "page-header",
        text = "Quest Rewards",
      },
      {
        style = "default",
        text = "When you complete a quest that offers rewards, that quest will be shown here. "..
               "Message the players listed below to find out how to claim your rewards.",
      }
    }
  }

  local article = addon.CustomWidgets:CreateWidget("ArticleText", frame, textinfo)
  article:ClearAllPoints(true)
  article:SetPoint("TOPLEFT", frame, "TOPLEFT")
  article:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
  article:SetHeight(90)

  local dtFrame = CreateFrame("Frame", nil, frame)
  dtFrame:SetPoint("TOPLEFT", article, "BOTTOMLEFT")
  dtFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

  local dtwb = addon.CustomWidgets:CreateWidget("DataTableWithButtons", dtFrame, options)
  local dataTable = dtwb:GetDataTable()
  dataTable:SubscribeMethodToEvents("RefreshData", "RewardDataLoaded", "RewardAdded", "RewardUpdated", "RewardDeleted", "RewardDataReset")
  dataTable:SubscribeMethodToEvents("ClearSelection", "RewardDataLoaded", "RewardDeleted", "RewardDataReset")
  dataTable:OnGetSelectedItem(function(row)
    return QuestRewards:FindByID(row[4])
  end)

  frame.dataTable = dataTable
end

function menu:OnShowMenu(frame)
  frame.dataTable:RefreshData()
  frame.dataTable:EnableUpdates(true)
end

function menu:OnLeaveMenu(frame)
  frame.dataTable:EnableUpdates(false)
end