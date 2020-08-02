local _, addon = ...
local loader = addon.QuestScriptLoader
local compiler = addon.QuestScriptCompiler
local tokens = addon.QuestScriptTokens

-- todo: add wider support for this newline behavior
local function subNewlines(str)
  return str:gsub([[\n]], "\n"):gsub("%%br", "\n\n"):gsub("\n ", "\n")
end

loader:AddScript(tokens.CMD_QUEST, tokens.METHOD_PARSE, function(quest, args)
  local cmdInfo = addon.QuestScript[tokens.CMD_QUEST]

  local name = compiler:GetValidatedParameterValue(tokens.PARAM_NAME, args, cmdInfo)
  if name then
    quest.name = name
  end

  local description = compiler:GetValidatedParameterValue(tokens.PARAM_DESCRIPTION, args, cmdInfo)
  if description then
    quest.description = subNewlines(description)
  end

  local completion = compiler:GetValidatedParameterValue(tokens.PARAM_COMPLETION, args, cmdInfo)
  if completion then
    quest.completion = subNewlines(completion)
  end
end)