local _, addon = ...

local parameter = addon.QuestEngine:NewParameter(addon.QuestScriptTokens.PARAM_TEXT)
parameter:AllowType("string", "table")

function parameter:OnParse(rawValue, options)
  local ret = {}
  if type(rawValue) == "string" then
    -- If a single text value is defined, it's used for all display texts
    ret = {
      log = rawValue,
      progress = rawValue,
      quest = rawValue,
    }
  elseif type(rawValue) == "table" then
    -- Only whitelisted text values can be set at the objective level
    -- todo: (#54) nested configuration tables should probably be configured in QuestScript
    -- https://github.com/dolphinspired/PlayerMadeQuests/issues/54
    ret = {
      log = rawValue.log,
      progress = rawValue.progress,
      quest = rawValue.quest,
    }
  end

  if options.defaultValue then
    -- Unspecified displayText scopes will use the checkpoint's default
    ret = addon:MergeTable(options.defaultValue, ret)
  end

  return ret
end