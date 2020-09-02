local _, addon = ...
local logger = addon.Logger:NewLogger("Compiler", addon.LogLevel.info)
local GetUnitName = addon.G.GetUnitName

addon.QuestScriptCompiler = {}
local compiler = addon.QuestScriptCompiler

--[[
  Parses a QuestScript "file" (set of lines) and/or a set of quest parameters
  into a Quest that can be stored in the QuestLog and tracked.
  See QuestLog.lua for the Quest data model.
--]]
function addon.QuestScriptCompiler:Compile(script, questParams)
  local quest

  -- First, parse the user-supplied script into a quest object
  if script ~= nil and script ~= "" then
    -- Parse the YAML script into Lua and validate it against the
    -- rules outlined in QuestScript
    local yaml = addon:ParseYaml(script, addon.QuestScript)
    -- Convert the parsed and validated YAML into a proper quest
    quest = addon:ParseQuest(yaml)
    -- logger:Table(quest)
  else
    quest = {}
  end

  -- Then, apply any questParams over top of whatever was created by the script
  if questParams then
    quest = addon:MergeTable(quest, questParams)
  end

  -- Finally, supply some default values for required fields that have not yet been defined
  if not quest.questId then
    local playerName = GetUnitName("player", true)
    if not playerName then
      error("Player name is required in order to generate a questId")
    end
    quest.questId = addon:CreateID("quest-"..playerName.."-%i")
  end
  if not quest.addonVersion then
    quest.addonVersion = addon.VERSION
  end
  if not quest.objectives then
    quest.objectives = {}
  end

  -- As a nice-to-have, give each objective a link back to its quest (not sure if this is still needed)
  for _, obj in ipairs(quest.objectives) do
    obj.questId = quest.questId
  end

  -- Verify with the QuestEngine that this quest will be runnable
  addon.QuestEngine:Validate(quest)

  logger:Trace("Quest compiled: %s", quest.questId)
  -- logger:Table(quest)
  return quest
end

function addon.QuestScriptCompiler:TryCompile(script, params)
  return pcall(compiler.Compile, compiler, script, params)
end