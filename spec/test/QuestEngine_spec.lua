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
    - talkto 3 "Stormwind Guard"
    - emote dance 2 Cow
]]

describe("QuestEngine", function()
  local quest, eventSpy
  setup(function()
    addon:Init()
    addon:Advance()
    eventSpy = events:SpyOnEvents(addon.AppEvents)
  end)
  before_each(function()
    quest = nil
    quest = nil
    eventSpy:Reset()
  end)
  describe("Validate", function()
    it("cannot validate a quest with no name", function()
      quest = compiler:Compile(goodScript)
      quest.name = nil
      assert.has_error(function() engine:Validate(quest) end)
    end)
    it("can validate a quest with no objectives", function()
      quest = compiler:Compile(nil, { name = "Objectiveless Quest" })
      engine:Validate(quest)
    end)
    it("can validate a quest with objectives", function()
      quest = compiler:Compile(goodScript)
      engine:Validate(quest)
      assert.equals(3, #quest.objectives)
    end)
    it("cannot build a quest with an invalid objective", function()
      local script = [[
        quest:
          name: bad quest
        objectives:
          - milk 5 Cow]]
          -- todo: is this error in the compiler or the engine?
      assert.has_error(function() compiler:Compile(script) end)
    end)
  end)
  describe("when a quest is added to the QuestLog", function()
    before_each(function()
      QuestLog:Clear()
      addon:Advance()
      quest = compiler:Compile(goodScript)
    end)
    describe("in the Active status", function()
      before_each(function()
        QuestLog:AddQuest(quest, QuestStatus.Active)
        addon:Advance()
        quest = QuestLog:FindByID(quest.questId)
      end)
      it("then quest tracking is started", function()
        local payload = eventSpy:GetPublishPayload("QuestTrackingStarted")
        assert.same(quest, payload)
      end)
      describe("and moved to another status", function()
        before_each(function()
          QuestLog:SetQuestStatus(quest.questId, QuestStatus.Abandoned)
          addon:Advance()
        end)
        it("then quest tracking is stopped", function()
          local payload = eventSpy:GetPublishPayload("QuestTrackingStopped")
          assert.same(quest, payload)
        end)
      end)
    end)
    describe("in any other status", function()
      before_each(function()
        QuestLog:AddQuest(quest, QuestStatus.Invited)
        addon:Advance()
        quest = QuestLog:FindByID(quest.questId)
      end)
      it("then quest tracking is not started", function()
        eventSpy:AssertNotPublished("QuestTrackingStarted")
      end)
      describe("and moved to Active", function()
        before_each(function()
          QuestLog:SetQuestStatus(quest.questId, QuestStatus.Active)
          addon:Advance()
        end)
        it("then quest tracking is started", function()
          local payload = eventSpy:GetPublishPayload("QuestTrackingStarted")
          assert.same(quest, payload)
        end)
      end)
    end)
  end)
  describe("Objective tracking", function()
    before_each(function()
      QuestLog:Clear()
      addon:Advance()
      quest = compiler:Compile(goodScript)
      QuestLog:AddQuest(quest, QuestStatus.Active)
      addon:Advance()
    end)
  end)
end)