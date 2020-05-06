local _, addon = ...
addon:traceFile("cmd/quest.lua")
local qs = addon.QuestScript

local cmd = addon.QuestScript:NewCommand("quest", "q")

function cmd:Parse(quest, args)
  local name = qs:GetArgsValue(args, "name", "n", 2)

  addon:info("quest name =", name)
  if name then
    quest.name = name
  end

  local description = qs:GetArgsValue(args, "description", "desc", "d", 3)
  if description then
    quest.description = description
  end
end