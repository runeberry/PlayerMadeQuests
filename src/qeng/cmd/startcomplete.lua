local _, addon = ...
local compiler, tokens = addon.QuestScriptCompiler, addon.QuestScript.tokens

local function parseStartComplete(cmdToken, args)
  local result = {}
  local cmdInfo = compiler:GetCommandInfo(cmdToken)

  result.displaytext = compiler:ParseDisplayText(args, cmdInfo)
  args[tokens.PARAM_TEXT] = nil

  result.conditions = compiler:ParseConditions(cmdInfo.params, args)

  return result
end

compiler:AddScript(tokens.CMD_START, tokens.METHOD_PARSE, function(quest, args)
  quest.start = parseStartComplete(tokens.CMD_START, args)
  quest.start.name = tokens.CMD_START
end)

compiler:AddScript(tokens.CMD_COMPLETE, tokens.METHOD_PARSE, function(quest, args)
  quest.complete = parseStartComplete(tokens.CMD_COMPLETE, args)
  quest.complete.name = tokens.CMD_COMPLETE
end)