local _, addon = ...
addon:traceFile("cmd/quest.lua")
local QuestEngine = addon.QuestEngine

local cmd = QuestEngine:NewCommand("quest", "q")

function cmd:Parse(quest, args)
  local name = QuestEngine:GetArgsValue(args, "name", "n", 2)

  if name then
    quest.name = name
  end

  local description = QuestEngine:GetArgsValue(args, "description", "desc", "d", 3)
  if description then
    quest.description = description
  end
end