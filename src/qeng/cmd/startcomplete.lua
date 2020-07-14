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
  quest.start = parseStartComplete(tokens.OBJ_START, args)
  quest.start.questId = quest.questId
end)

compiler:AddScript(tokens.CMD_COMPLETE, tokens.METHOD_PARSE, function(quest, args)
  quest.complete = parseStartComplete(tokens.OBJ_COMPLETE, args)
  quest.complete.questId = quest.questId
end)