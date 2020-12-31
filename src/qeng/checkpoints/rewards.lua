local _, addon = ...
local tokens = addon.QuestScriptTokens

-- todo: Rewards doesn't really fit in as a Checkpoint since it isn't evaluated.
-- But it is parsed as a top-level entity, much like quest name, description, etc.
-- I should really separate the "parsing" and "evaluating" responsibilities of Checkpoints.
local checkpoint = addon.QuestEngine:NewCheckpoint("rewards")

checkpoint:AddParameter(tokens.PARAM_PLAYER, { required = true })
checkpoint:AddParameter(tokens.PARAM_REWARDCHOICE)
checkpoint:AddParameter(tokens.PARAM_REWARDMONEY, { alias = tokens.PARAM_MONEY })
checkpoint:AddParameter(tokens.PARAM_REWARDITEM, { alias = tokens.PARAM_ITEM })

checkpoint:AddParameter(tokens.PARAM_TEXT, {
  defaultValue = {
    -- log = "",
    -- progress = "",
    quest = "Trade with %player to receive [%rc:one of ]the following rewards:",
    full = "Trade with %player to receive [%rc:one of ]the following rewards:"
  },
})

function checkpoint:OnParse(rewards)
  -- Extract the "player" parameter to an array of reward givers
  rewards.givers = {}
  for playerName in pairs(rewards.parameters[tokens.PARAM_PLAYER]) do
    rewards.givers[#rewards.givers+1] = playerName
  end

  if rewards.parameters[tokens.PARAM_REWARDITEM] then
    rewards.choice = (rewards.parameters[tokens.PARAM_REWARDCHOICE] and true) or false

    rewards.items = {}
    for i, item in ipairs(rewards.parameters[tokens.PARAM_REWARDITEM]) do
      rewards.items[i] = {
        itemId = item.itemId,
        quantity = item.quantity,
      }
    end

    -- Validation: can't require a reward choice with <2 rewards to choose from
    if rewards.choice and #rewards.items < 2 then
      error("Parameter '"..tokens.PARAM_REWARDCHOICE.."' cannot be set to true if there are fewer than 2 rewards to choose from.", 0)
    end
  end

  if rewards.parameters[tokens.PARAM_REWARDMONEY] then
    rewards.money = rewards.parameters[tokens.PARAM_REWARDMONEY]
  end
end