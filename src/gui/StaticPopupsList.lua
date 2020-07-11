local _, addon = ...
local QuestLog, QuestStatus = addon.QuestLog, addon.QuestStatus

addon.StaticPopupsList = {
  ["AbandonQuest"] = {
    message = function(quest)
      return "Are you sure you want to abandon\n"..addon:Enquote(quest.name, '""?')
    end,
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function(quest)
      QuestLog:SaveWithStatus(quest, QuestStatus.Abandoned)
      addon:PlaySound("QuestAbandoned")
      addon.Logger:Warn("Quest abandoned:", quest.name)
    end,
  },
  ["ArchiveQuest"] = {
    message = function(quest)
      return "Archive "..addon:Enquote(quest.name, '""?\n')..
             "This will hide the quest from your Quest Log, but PMQ will remember that you completed it."
    end,
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function(quest)
      QuestLog:SaveWithStatus(quest, QuestStatus.Archived)
    end,
  },
  ["DeleteQuest"] = {
    message = function(quest)
      return "Are you sure you want to delete "..addon:Enquote(quest.name, '""?\n')..
             "This will delete the quest entirely from your log, and PMQ will forget you ever had it!"
    end,
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function(quest)
      QuestLog:Delete(quest.questId)
      addon.Logger:Warn("Quest deleted:", quest.name)
    end,
  },
  ["ResetQuestLog"] = {
    message = "Are you sure you want to reset your quest log?\n"..
              "This will delete ALL quest log history, including archived quests!",
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function()
      QuestLog:Clear()
      addon:PlaySound("QuestAbandoned")
      addon.Logger:Warn("Quest Log reset")
    end,
  },
  ["RetryQuest"] = {
    message = function(quest)
      if quest.status == QuestStatus.Finished then
        -- Provide an additional warning only if the quest has already been successfully finished
        return "Replay "..addon:Enquote(quest.name, '""?').."\nThis will erase your previous completion of this quest."
      else
        return "Replay "..addon:Enquote(quest.name, '""?')
      end
    end,
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function(quest)
      QuestLog:SaveWithStatus(quest, QuestStatus.Active)
    end,
  },
  ["DeleteCatalogItem"] = {
    message = function(catalogItem)
      return "Are you sure you want to delete\n"..addon.Enquote(catalogItem.quest.name, '""?')
    end,
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function(catalogItem)
      addon.QuestCatalog:Delete(catalogItem.quest.questId)
      addon.Logger:Warn("Catalog item deleted:", catalogItem.quest.name)
    end,
  },
  ["ExitDraft"] = {
    message = "You have unsaved changes.\nWould you like to save?",
    yesText = "Discard",
    noText = "Cancel",
    otherText = "Save",
    yesHandler = function()
      addon.MainMenu:NavToMenuScreen("drafts")
    end,
    otherHandler = function(saveFunction)
      saveFunction()
      addon.MainMenu:NavToMenuScreen("drafts")
    end,
  },
  ["DeleteDraft"] = {
    message = function(draftId, draftName)
      return "Are you sure you want to delete\n"..addon:Enquote(draftName, '""?')
    end,
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function(draftId, draftName)
      addon.QuestDrafts:Delete(draftId)
      addon.Logger:Warn("Draft deleted:", draftName)
    end,
  },
}