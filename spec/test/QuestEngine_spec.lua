local builder = require("spec/addon-builder")
local events = require("spec/events")
local addon = builder:Build()
local engine, compiler = addon.QuestEngine, addon.QuestScriptCompiler
local QuestLog, QuestStatus = addon.QuestLog, addon.QuestStatus

local goodScript = [[objective kill 5 Chicken
objective talkto 3 "Stormwind Guard"
objective emote 2 dance Cow]]

-- For testing: compiles a script with some default parameters
local function makeParams(script)
  local params = {
    name = "Test Quest",
    description = "I sure hope these tests pass!"
  }
  return compiler:Compile(script, params)
end

-- For testing: given a script, creates a built quest with some default parameters
local function quickBuild(script)
  local p = makeParams(script)
  return engine:Build(p)
end

local function assertBuilt(quest)
  assert(quest._built, "quest has not been built")
end

describe("QuestEngine", function()
  local params, quest, eventSpy
  setup(function()
    addon:Init()
    addon:Advance()
    eventSpy = events:SpyOnEvents(addon.AppEvents)
  end)
  before_each(function()
    params = nil
    quest = nil
    eventSpy:Reset()
  end)
  describe("Build", function()
    it("cannot build a quest with no name", function()
      params = makeParams()
      params.name = nil
      assert.has_error(function() engine:Build(params) end)
    end)
    it("can build a quest with no objectives", function()
      quest = quickBuild()
      assertBuilt(quest)
      assert.equals(0, #quest.objectives)
    end)
    it("can build a quest with objectives", function()
      quest = quickBuild(goodScript)
      assertBuilt(quest)
      assert.equals(3, #quest.objectives)
    end)
    it("cannot build a quest with an invalid objective", function()
      local script = [[objective milk 5 Cow]]
      assert.has_error(function() quickBuild(script) end)
    end)
  end)
  describe("when a quest is added to the QuestLog", function()
    before_each(function()
      QuestLog:Clear()
      addon:Advance()
      params = makeParams(goodScript)
    end)
    describe("in the Active status", function()
      before_each(function()
        QuestLog:AddQuest(params, QuestStatus.Active)
        addon:Advance()
        quest = QuestLog:FindByID(params.id)
      end)
      it("then quest tracking is started", function()
        local payload = eventSpy:GetPublishPayload("QuestTrackingStarted")
        assertBuilt(payload)
        assert.same(quest, payload)
      end)
      describe("and moved to another status", function()
        before_each(function()
          QuestLog:SetQuestStatus(quest.id, QuestStatus.Abandoned)
          addon:Advance()
        end)
        it("then quest tracking is stopped", function()
          local payload = eventSpy:GetPublishPayload("QuestTrackingStopped")
          assertBuilt(payload)
          assert.same(quest, payload)
        end)
      end)
    end)
    describe("in any other status", function()
      before_each(function()
        QuestLog:AddQuest(params, QuestStatus.Invited)
        addon:Advance()
        quest = QuestLog:FindByID(params.id)
      end)
      it("then quest tracking is not started", function()
        eventSpy:AssertNotPublished("QuestTrackingStarted")
      end)
      describe("and moved to Active", function()
        before_each(function()
          QuestLog:SetQuestStatus(quest.id, QuestStatus.Active)
          addon:Advance()
        end)
        it("then quest tracking is started", function()
          local payload = eventSpy:GetPublishPayload("QuestTrackingStarted")
          assertBuilt(payload)
          assert.same(quest, payload)
        end)
      end)
    end)
  end)
  describe("Objective tracking", function()
    before_each(function()
      QuestLog:Clear()
      addon:Advance()
      params = makeParams(goodScript)
      QuestLog:AddQuest(params, QuestStatus.Active)
      addon:Advance()
    end)
  end)
end)