local _, addon = ...
addon:traceFile("cmd/quest.lua")
local QuestEngine, tokens = addon.QuestEngine, addon.QuestScript.tokens

QuestEngine:AddScript(tokens.CMD_QUEST_SCRIPT, function(quest, args)
  local name = QuestEngine:GetArgsValue(args, "name", "n", 2)
  if name then
    quest.name = name
  end

  local description = QuestEngine:GetArgsValue(args, "description", "desc", "d", 3)
  if description then
    quest.description = description
  end
end)