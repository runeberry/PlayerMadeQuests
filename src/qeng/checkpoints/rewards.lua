local _, addon = ...
local tokens = addon.QuestScriptTokens

-- todo: Rewards doesn't really fit in as a Checkpoint since it isn't evaluated.
-- But it is parsed as a top-level entity, much like quest name, description, etc.
-- I should really separate the "parsing" and "evaluating" responsibilities of Checkpoints.
local checkpoint = addon.QuestEngine:NewCheckpoint("rewards")

checkpoint:AddParameter(tokens.PARAM_PLAYER, { required = true })
checkpoint:AddParameter(tokens.PARAM_REWARDMONEY, { alias = tokens.PARAM_MONEY })
checkpoint:AddParameter(tokens.PARAM_REWARDITEM, { alias = tokens.PARAM_ITEM })
