local builder = require("spec/addon-builder")
local addon = builder:Build()
local events = require("spec/events")
local game = require("spec/game-env")

local goodScript = [[
  quest:
    name: Test Quest
    description: I sure hope these tests pass!
  objectives:
    - kill 5 Chicken
    - talk-to 3 "Stormwind Guard"
    - use-emote dance 2 Cow
]]

describe("QuestTracking", function()
  local QuestLog, QuestStatus = addon.QuestLog, addon.QuestStatus
  local QuestCatalog, QuestCatalogStatus = addon.QuestCatalog, addon.QuestCatalogStatus
  local compiler = addon.QuestScriptCompiler
  local eventSpy

  setup(function()
    addon:Init()
    eventSpy = events:SpyOnEvents(addon.MessageEvents)
  end)
  before_each(function()
    QuestLog:DeleteAll()
    QuestCatalog:DeleteAll()
    addon:Advance()
    eventSpy:Reset()
    game:ResetEnv(addon)
  end)
  it("can notify quest author on status change", function()
    -- First, compile a quest with a known author
    local tempAddon = builder:Build()
    local authorName = "AuthorName"
    game:SetPlayerInfo(tempAddon, { name = authorName })
    tempAddon:Init()
    local quest = tempAddon.QuestScriptCompiler:Compile(goodScript)
    assert.equals(authorName, quest.metadata.authorName)

    -- Then, switch back to the default test player and save the quest just before turn-in
    QuestLog:SaveWithStatus(quest, QuestStatus.Finished)
    addon:Advance()

    -- Finally, update the quest's status and look for the update message
    eventSpy:Reset()
    QuestLog:SaveWithStatus(quest, QuestStatus.Completed)
    addon:Advance()
    eventSpy:AssertPublished("QuestStatusChanged", 1)
  end)
  it("can notify quest sharer on status change", function()
    -- First, have another player compile and share a quest
    game:SetPlayerInfo(addon, { name = "AnotherPlayer" })
    game:SetPlayerGroup(addon, "PARTY")
    local quest = compiler:Compile(goodScript)
    addon:ShareQuest(quest)
    game:ResetEnv(addon)
    addon:Advance()

    -- Then, accept the quest (this is a little bit manual)
    local catalogItem = QuestCatalog:FindByID(quest.questId)
    QuestCatalog:SaveWithStatus(catalogItem, QuestCatalogStatus.Accepted)
    QuestLog:SaveWithStatus(quest, QuestStatus.Finished)
    addon:Advance()

    -- Finally, update the quest's status and look for the update message
    eventSpy:Reset()
    QuestLog:SaveWithStatus(quest, QuestStatus.Completed)
    addon:Advance()
    eventSpy:AssertPublished("QuestStatusChanged", 1)
  end)
  it("can notify party on status change", function()
    -- First, add a quest to the player's log
    local quest = compiler:Compile(goodScript)
    QuestLog:SaveWithStatus(quest, QuestStatus.Finished)
    addon:Advance()

    -- Then, put the player in a party
    game:SetPlayerGroup(addon, "PARTY")

    -- Finally, update the quest's status and look for the update message
    eventSpy:Reset()
    QuestLog:SaveWithStatus(quest, QuestStatus.Completed)
    addon:Advance()
    eventSpy:AssertPublished("QuestStatusChanged", 1)
  end)
  it("can notify raid on status change", function()
    -- First, add a quest to the player's log
    local quest = compiler:Compile(goodScript)
    QuestLog:SaveWithStatus(quest, QuestStatus.Finished)
    addon:Advance()

    -- Then, put the player in a raid
    game:SetPlayerGroup(addon, "RAID")

    -- Finally, update the quest's status and look for the update message
    eventSpy:Reset()
    QuestLog:SaveWithStatus(quest, QuestStatus.Completed)
    addon:Advance()
    eventSpy:AssertPublished("QuestStatusChanged", 1)
  end)
end)