local builder = require("spec/addon-builder")
local events = require("spec/events")
local game = require("spec/game-env")
local mock = require("spec/mock")
local addon = builder:Build()
local engine, compiler = addon.QuestEngine, addon.QuestScriptCompiler
local QuestLog, QuestStatus = addon.QuestLog, addon.QuestStatus

local questStub = [[
  quest:
    name: Aura Quest 1
  objectives:
    - %s
]]

local function addActiveQuest(script)
  local quest = compiler:Compile(string.format(questStub, script))
  QuestLog:SaveWithStatus(quest, QuestStatus.Active)
  addon:Advance()
  return quest
end

local function testObjectiveCompleted(script)
  it("then the condition passes", function()
    local quest = addActiveQuest(script)
    local objective = quest.objectives[1]
    local appEventSpy = events:SpyOnEvents(addon.AppEvents)
    -- addon:ForceLogs(function()
      addon.QuestEvents:Publish(objective.name)
      addon:Advance()
    -- end)
    local payload = appEventSpy:GetPublishPayload("ObjectiveCompleted", 1)
    assert.is_not_nil(payload)
    assert.same(objective.id, payload.id)

  end)
end

local function testObjectiveNotCompleted(script)
  it("then the condition fails", function()
    local quest = addActiveQuest(script)
    local objective = quest.objectives[1]
    local appEventSpy = events:SpyOnEvents(addon.AppEvents)
    -- addon:ForceLogs(function()
      addon.QuestEvents:Publish(objective.name)
      addon:Advance()
    -- end)
    appEventSpy:AssertNotPublished("ObjectiveCompleted")
  end)
end

describe("Condition", function()
  setup(function()
    addon:Init()
    addon:Advance()
  end)
  before_each(function()
    QuestLog:DeleteAll()
    addon:Advance()
  end)
  describe("aura", function()
    setup(function()
      game:AddPlayerAura(addon, { name = "Blessing of Might", spellId = 1234 })
      game:AddPlayerAura(addon, { name = "Underwater Breathing", spellId = 1235 })
      game:SetPlayerTarget(addon, "Chicken")
    end)
    teardown(function()
      game:ResetEnv(addon)
    end)
    describe("when player has aura", function()
      testObjectiveCompleted("talk-to: { target: Chicken, aura: Blessing of Might }")
    end)
    describe("when player has one of multiple auras", function()
      testObjectiveCompleted("talk-to: { target: Chicken, aura: [ Blessing of Might, 'Power Word: Fortitude' ] }")
    end)
    describe("when player does not have the aura", function()
      testObjectiveNotCompleted("talk-to: { target: Chicken, aura: 'Power Word: Fortitude' }")
    end)
    describe("when player does not have any of multiple auras", function()
      testObjectiveNotCompleted("talk-to: { target: Chicken, aura: [ 'Power Word: Fortitude', Mage Armor ] }")
    end)
  end)
  describe("emote", function()

  end)
  describe("item", function()

  end)
  describe("killtarget", function()

  end)
  describe("position", function()

  end)
  describe("target", function()

  end)
end)