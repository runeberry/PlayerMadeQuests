local _, addon = ...
addon:traceFile("cmd/quest.lua")
local compiler, tokens = addon.QuestScriptCompiler, addon.QuestScript.tokens

compiler:AddScript(tokens.CMD_QUEST, tokens.METHOD_PARSE, function(quest, args)
  local cmdInfo = compiler:GetCommandInfo(tokens.CMD_QUEST)

  local name = compiler:GetValidatedParameterValue(tokens.PARAM_NAME, args, cmdInfo)
  if name then
    quest.name = name
  end

  local description = compiler:GetValidatedParameterValue(tokens.PARAM_DESCRIPTION, args, cmdInfo)
  if description then
    quest.description = description
  end

  local completion = compiler:GetValidatedParameterValue(tokens.PARAM_COMPLETION, args, cmdInfo)
  if completion then
    quest.completion = completion
  end
end)