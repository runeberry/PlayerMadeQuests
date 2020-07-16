local _, addon = ...
local loader = addon.QuestScriptLoader
local compiler = addon.QuestScriptCompiler
local tokens = addon.QuestScriptTokens

local function parseStartComplete(objToken, args)
  local ok, objective = pcall(compiler.ParseObjective, compiler, { [objToken] = args })
  if not ok then
    error("Failed to parse "..objToken.." objective: "..objective)
  end
  return objective
end

loader:AddScript(tokens.CMD_START, tokens.METHOD_PARSE, function(quest, args)
  quest.start = parseStartComplete(tokens.CMD_START, args)
  quest.start.questId = quest.questId
end)

loader:AddScript(tokens.CMD_COMPLETE, tokens.METHOD_PARSE, function(quest, args)
  quest.complete = parseStartComplete(tokens.CMD_COMPLETE, args)
  quest.complete.questId = quest.questId
end)

-- todo: Populate these methods
loader:AddScript(tokens.CMD_START, tokens.METHOD_EVAL, function() end)
loader:AddScript(tokens.CMD_COMPLETE, tokens.METHOD_EVAL, function() end)