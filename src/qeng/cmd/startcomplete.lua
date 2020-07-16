local _, addon = ...
local compiler, tokens = addon.QuestScriptCompiler, addon.QuestScript.tokens

local function parseStartComplete(objToken, args)
  local ok, objective = pcall(compiler.ParseObjective, compiler, { [objToken] = args })
  if not ok then
    error("Failed to parse "..objToken.." objective: "..objective)
  end
  return objective
end

compiler:AddScript(tokens.CMD_START, tokens.METHOD_PARSE, function(quest, args)
  quest.start = parseStartComplete(tokens.CMD_START, args)
  quest.start.questId = quest.questId
end)

compiler:AddScript(tokens.CMD_COMPLETE, tokens.METHOD_PARSE, function(quest, args)
  quest.complete = parseStartComplete(tokens.CMD_COMPLETE, args)
  quest.complete.questId = quest.questId
end)

-- todo: Populate these methods
compiler:AddScript(tokens.CMD_START, tokens.METHOD_EVAL, function() end)
compiler:AddScript(tokens.CMD_COMPLETE, tokens.METHOD_EVAL, function() end)