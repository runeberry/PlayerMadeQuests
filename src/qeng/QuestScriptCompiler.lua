local _, addon = ...
local logger = addon.Logger:NewLogger("Compiler", addon.LogLevel.info)
local GetBuildInfo, UnitFullName = addon.G.GetBuildInfo, addon.G.UnitFullName
local time = addon.G.time
local Ace, LibCompress = addon.Ace, addon.LibCompress

addon.QuestScriptCompiler = {}
local compiler = addon.QuestScriptCompiler

local function buildMetadata()
  local _, build, _, tocVersion = GetBuildInfo()
  local playerName, playerRealm = UnitFullName("player")

  local metadata = {
    addonVersion = addon.VERSION,
    authorName = playerName,
    authorRealm = playerRealm,
    compileDate = time(),

    clientVersion = tocVersion,
    clientBuild = addon:TryConvertString(build),
  }

  return metadata
end

local function signObjectiveHashes(quest)
  if not quest.objectives then return end

  for _, obj in ipairs(quest.objectives) do
    -- An objective's id must be both globally unique and reproducible.
    -- * Must be unique among all quests and all objectives on this character. (questId)
    -- * Must be the same between compilations if its content did not change. (serialized obj)
    local hash = LibCompress:fcs32init()
    hash = LibCompress:fcs32update(hash, quest.questId)
    hash = LibCompress:fcs32update(hash, Ace:Serialize(obj))
    hash = LibCompress:fcs32final(hash)

    obj.id = "obj-"..tostring(hash)
  end
end

local function signQuestHash(quest)
  -- Temporarily remove metadata from the quest, as it should not affect the hash
  local metadata = quest.metadata
  quest.metadata = nil

  metadata.hash = tostring(addon:GetTableHash(quest))

  quest.metadata = metadata
end

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
    local playerName, playerRealm = UnitFullName("player")
    if not playerName or not playerRealm then
      error("Player name and realm are required in order to generate a questId")
    end
    quest.questId = addon:CreateID("quest-"..playerName.."-"..playerRealm.."-%i")
  end
  if not quest.objectives then
    quest.objectives = {}
  end

  -- Give each objective a link back to its quest
  for _, obj in ipairs(quest.objectives) do
    obj.questId = quest.questId
  end

  -- Finally, add some non-essential data to help recipients and future addon versions
  -- know where this quest came from and how it was compiled
  local metadata = buildMetadata()
  if quest.metadata then
    -- If metadata was provied in params, then those fields will take priority
    metadata = addon:MergeTable(metadata, quest.metadata)
  end
  quest.metadata = metadata

  -- Assign predictable ids to all objectives
  signObjectiveHashes(quest)

  -- Final step: sign the quest with a hash
  signQuestHash(quest)

  -- Verify with the QuestEngine that this quest will be runnable
  addon.QuestEngine:Validate(quest)

  logger:Trace("Quest compiled: %s", quest.questId)
  -- logger:Table(quest)
  return quest
end

function addon.QuestScriptCompiler:TryCompile(script, params)
  return pcall(compiler.Compile, compiler, script, params)
end