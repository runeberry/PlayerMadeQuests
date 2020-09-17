local builder = require("spec/addon-builder")
local events = require("spec/events")
local addon = builder:Build()
local engine, compiler = addon.QuestEngine, addon.QuestScriptCompiler
local QuestLog, QuestStatus = addon.QuestLog, addon.QuestStatus

local goodScript = [[
  quest:
    name: Test Quest
    description: I sure hope these tests pass!
  objectives:
    - kill 5 Chicken
    - talk-to 3 "Stormwind Guard"
    - use-emote dance 2 Cow
]]

describe("QuestEngine", function()
  local eventSpy
  setup(function()
    addon:Init()
    addon:Advance()
    eventSpy = events:SpyOnEvents(addon.AppEvents)
  end)
  before_each(function()
    eventSpy:Reset()
  end)
  describe("Validate", function()
    it("cannot validate a quest with no name", function()
      local quest = compiler:Compile(goodScript)
      quest.name = nil
      assert.has_error(function() engine:Validate(quest) end)
    end)
    it("can validate a quest with no objectives", function()
      local quest = compiler:Compile(nil, { name = "Objectiveless Quest" })
      engine:Validate(quest)
    end)
    it("can validate a quest with objectives", function()
      local quest = compiler:Compile(goodScript)
      engine:Validate(quest)
      assert.equals(3, #quest.objectives)
    end)
    it("cannot build a quest with an invalid objective", function()
      local script = [[
        quest:
          name: bad quest
        objectives:
          - milk 5 Cow]]
      -- this error actually happens in Validate, but Compile now calls Validate so... ¯\_(ツ)_/¯
      assert.has_error(function() compiler:Compile(script) end)
    end)
  end)
  describe("when a quest is added to the QuestLog", function()
    local quest
    before_each(function()
      QuestLog:DeleteAll()
      addon:Advance()
      eventSpy:Reset()
      quest = compiler:Compile(goodScript)
    end)
  end)
  describe("Objective tracking", function()
    before_each(function()
      QuestLog:DeleteAll()
      addon:Advance()
      local quest = compiler:Compile(goodScript)
      QuestLog:SaveWithStatus(quest, QuestStatus.Active)
      addon:Advance()
    end)
  end)
end)