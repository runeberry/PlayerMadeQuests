local addon = require("spec/addon-builder"):Build()
local events = require("spec/events")
local game = require("spec/game-env")

local goodScript = [[
  quest:
    name: Shared Quest
    description: I sure hope these tests pass!
  objectives:
    - kill 5 Chicken
    - talk-to 3 "Stormwind Guard"
    - use-emote dance 2 Cow
]]

local goodScriptWithRequirements = goodScript..[[
  required:
    level: 5]]

describe("ShareQuest", function()
  local QuestLog, QuestStatus = addon.QuestLog, addon.QuestStatus
  local QuestArchive = addon.QuestArchive
  local QuestCatalog, QuestCatalogStatus = addon.QuestCatalog, addon.QuestCatalogStatus

  local eventSpy, questToShare

  local function assertResponded(event)
    local options = eventSpy:GetPublishPayload(event)
    assert.equals(addon.MessageDistribution.Whisper, options.distribution)
    assert.equals("*yourself*", options.target)
  end

  setup(function()
    addon:Init()
    eventSpy = events:SpyOnEvents(addon.MessageEvents)
  end)
  before_each(function()
    addon:Advance()
    eventSpy:Reset()
    game:ResetEnv(addon)
    questToShare = addon.QuestScriptCompiler:Compile(goodScript)
    game:SetPlayerGroup(addon, "PARTY")
  end)
  describe("when a quest is shared", function()
    it("then quest status is cleared on publish", function()
      questToShare.status = addon.QuestStatus.Active
      addon:ShareQuest(questToShare)
      local _, sharedQuest = eventSpy:GetPublishPayload("QuestInvite")
      assert.is_nil(sharedQuest.status)
    end)
    it("then quest progress is cleared on publish", function()
      questToShare.objectives[1].progress = 1
      addon:ShareQuest(questToShare)
      local _, sharedQuest = eventSpy:GetPublishPayload("QuestInvite")
      assert.equals(0, sharedQuest.objectives[1].progress)
    end)
    it("then invalid quests are rejected", function()
      questToShare.name = nil
      assert.has_error(function() addon:ShareQuest(questToShare) end)
    end)
  end)
  describe("when a shared quest is received", function()
    local sharedQuest
    before_each(function()
      addon:ShareQuest(questToShare, true)
      sharedQuest = questToShare
    end)
    after_each(function()
      QuestCatalog:DeleteAll()
      QuestLog:DeleteAll()
      QuestArchive:DeleteAll()
      addon:Advance()
    end)
    it("then the shared quest is saved to the QuestCatalog", function()
      addon:Advance()
      local catalogItem = QuestCatalog:FindByID(sharedQuest.questId)
      assert.is_not_nil(catalogItem)
      assert.same(sharedQuest, catalogItem.quest)
    end)
    describe("and the quest is already in the Catalog", function()
      local catalogItem
      before_each(function()
        catalogItem = QuestCatalog:NewCatalogItem(addon:CopyTable(sharedQuest))
        catalogItem.quest.name = catalogItem.quest.name.." (Catalog)"
        QuestCatalog:SaveWithStatus(catalogItem, QuestCatalogStatus.Invited)
      end)
      it("then newer shared quest versions are saved to the Catalog", function()
        catalogItem.quest.metadata.compileDate = sharedQuest.metadata.compileDate - 1
        catalogItem.quest.metadata.hash = sharedQuest.metadata.hash.."-different"
        QuestCatalog:Save(catalogItem)

        addon:Advance()
        local updatedCatalogItem = QuestCatalog:FindByID(sharedQuest.questId)
        assert.same(sharedQuest, updatedCatalogItem.quest)
      end)
      it("then newer shared quest versions with the same hash are not saved to the Catalog", function()
        catalogItem.quest.metadata.compileDate = sharedQuest.metadata.compileDate - 1
        catalogItem.quest.metadata.hash = sharedQuest.metadata.hash -- Already setup, just here for emphasis
        QuestCatalog:Save(catalogItem)

        addon:Advance()
        local updatedCatalogItem = QuestCatalog:FindByID(sharedQuest.questId)
        assert.same(catalogItem.quest, updatedCatalogItem.quest)
      end)
      it("then older shared quest versions are not saved to the Catalog", function()
        catalogItem.quest.metadata.compileDate = sharedQuest.metadata.compileDate + 1
        catalogItem.quest.metadata.hash = sharedQuest.metadata.hash.."-different"
        QuestCatalog:Save(catalogItem)

        addon:Advance()
        local updatedCatalogItem = QuestCatalog:FindByID(sharedQuest.questId)
        assert.same(catalogItem.quest, updatedCatalogItem.quest)
      end)
      it("then shared quests of the same version are not saved to the Catalog", function()
        catalogItem.quest.metadata.compileDate = sharedQuest.metadata.compileDate -- Already setup, just here for emphasis
        catalogItem.quest.metadata.hash = sharedQuest.metadata.hash -- Already setup, just here for emphasis
        QuestCatalog:Save(catalogItem)

        addon:Advance()
        local updatedCatalogItem = QuestCatalog:FindByID(sharedQuest.questId)
        assert.same(catalogItem.quest, updatedCatalogItem.quest)
        eventSpy:AssertNotPublished("QuestInviteDuplicate") -- Just gonna slip this check in here
      end)
    end)
    describe("and the quest is already in the QuestLog", function()
      local questLogQuest, catalogItem
      before_each(function()
        catalogItem = QuestCatalog:NewCatalogItem(addon:CopyTable(sharedQuest))
        catalogItem.quest.name = catalogItem.quest.name.." (Catalog)"
        QuestCatalog:SaveWithStatus(catalogItem, QuestCatalogStatus.Accepted)

        questLogQuest = addon:CopyTable(catalogItem.quest)
        QuestLog:SaveWithStatus(questLogQuest, QuestStatus.Active)
      end)
      it("then the sender is notified of 'duplicate' quests", function()
        -- Setup: Active is already considered a duplicate status

        addon:Advance()
        assertResponded("QuestInviteDuplicate")
      end)
      it("then the sender is not notified of 'non-duplicate' quests", function()
        QuestLog:SaveWithStatus(questLogQuest, QuestStatus.Abandoned)

        addon:Advance()
        eventSpy:AssertNotPublished("QuestInviteDuplicate")
      end)
      it("then older catalog versions will still be updated", function()
        catalogItem.quest.metadata.compileDate = catalogItem.quest.metadata.compileDate - 10
        catalogItem.quest.metadata.hash = catalogItem.quest.metadata.hash.."-different"
        QuestCatalog:Save(catalogItem)

        addon:Advance()
        local updatedCatalogQuest = QuestCatalog:FindByID(sharedQuest.questId)
        assert.same(sharedQuest, updatedCatalogQuest.quest)
        assert.not_same(catalogItem.quest, updatedCatalogQuest.quest)
      end)
    end)
    describe("and the quest is already in the QuestArchive", function()
      local archiveQuest, catalogItem
      before_each(function()
        catalogItem = QuestCatalog:NewCatalogItem(addon:CopyTable(questToShare))
        catalogItem.quest.name = catalogItem.quest.name.." (Catalog)"
        QuestCatalog:SaveWithStatus(catalogItem, QuestCatalogStatus.Accepted)

        archiveQuest = addon:CopyTable(catalogItem.quest)
        archiveQuest.status = QuestStatus.Completed
        QuestArchive:Save(archiveQuest)
      end)
      it("then the sender is notified of 'duplicate' quests", function()
        -- Setup: Completed is already considered a duplicate status

        addon:Advance()
        assertResponded("QuestInviteDuplicate")
      end)
      it("then the sender is not notified of 'non-duplicate' quests", function()
        archiveQuest.status = QuestStatus.Failed
        QuestArchive:Save(archiveQuest)

        addon:Advance()
        eventSpy:AssertNotPublished("QuestInviteDuplicate")
      end)
    end)
  end)
  describe("when a shared quest is received with requirements", function()
    local sharedQuest
    before_each(function()
      sharedQuest = addon.QuestScriptCompiler:Compile(goodScriptWithRequirements)
      addon:ShareQuest(sharedQuest, true)
    end)
    describe("and the player meets the requirements", function()
      before_each(function()
        game:SetPlayerInfo(addon, { level = 60 })
      end)
      it("then the quest is saved to the catalog", function()
        addon:Advance()
        local catalogItem = QuestCatalog:FindByID(sharedQuest.questId)
        assert.is_not_nil(catalogItem)
        assert.same(sharedQuest, catalogItem.quest)
      end)
    end)
    describe("and the player does not meet the requirements", function()
      before_each(function()
        game:SetPlayerInfo(addon, { level = 1 })
      end)
      it("then the quest is still saved to the Catalog", function()
        addon:Advance()
        local catalogItem = QuestCatalog:FindByID(sharedQuest.questId)
        assert.is_not_nil(catalogItem)
        assert.same(sharedQuest, catalogItem.quest)
      end)
      it("then the sender is notified", function()
        addon:Advance()
        assertResponded("QuestInviteRequirements")
      end)
    end)
  end)
  describe("when a shared catalog item is received (legacy behavior)", function()
    it("then the quest is declined", function()
      -- Previously, catalog items were shared instead of just quests
      -- If the handler sees something like this, just reject it
      local catalogItem = addon.QuestCatalog:NewCatalogItem(questToShare)
      addon.MessageEvents:Publish("QuestInvite", nil, catalogItem)

      addon:Advance()
      assertResponded("QuestInviteDeclined")
    end)
  end)
end)