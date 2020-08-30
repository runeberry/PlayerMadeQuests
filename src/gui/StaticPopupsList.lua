local _, addon = ...
local QuestLog, QuestStatus = addon.QuestLog, addon.QuestStatus
local QuestArchive = addon.QuestArchive
local location = addon.Locations

addon.StaticPopupsList = {
  ["AbandonQuest"] = {
    message = function(quest)
      return "Are you sure you want to abandon\n"..
             "\"%s\"?", quest.name
    end,
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function(quest)
      QuestLog:SaveWithStatus(quest, QuestStatus.Abandoned)
      addon:PlaySound("QuestAbandoned")
      addon.Logger:Warn("Quest abandoned: %s", quest.name)
    end,
  },
  ["ArchiveQuest"] = {
    message = function(quest)
      return "Archive \"%s\"?\n"..
             "This will hide the quest from your Quest Log, but PMQ will remember that you completed it.", quest.name
    end,
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function(quest)
      QuestArchive:Save(quest)
      QuestLog:Delete(quest)
    end,
  },
  ["DeleteQuest"] = {
    message = function(quest)
      return "Are you sure you want to delete \"%s\"?\n"..
             "This will delete the quest entirely from your log, and PMQ will forget you ever had it!", quest.name
    end,
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function(quest)
      QuestLog:Delete(quest.questId)
      addon.Logger:Warn("Quest deleted: %s", quest.name)
    end,
  },
  ["ResetQuestLog"] = {
    message = "Are you sure you want to reset your quest log?\n"..
              "This will delete ALL quests in your log!",
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function()
      QuestLog:DeleteAll()
      addon:PlaySound("QuestAbandoned")
      addon.Logger:Warn("Quest Log cleared")
    end,
  },
  ["RetryQuest"] = {
    message = function(quest)
      if quest.status == QuestStatus.Completed then
        -- Provide an additional warning only if the quest has already been successfully finished
        return "Replay \"%s\"?\n"..
               "This will erase your previous completion of this quest.", quest.name
      else
        return "Replay \"%s\"?", quest.name
      end
    end,
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function(quest)
      QuestLog:SaveWithStatus(quest, QuestStatus.Active)
      if QuestArchive:FindByID(quest.questId) then
        -- If the quest was in the archive, remove it from there
        QuestArchive:Delete(quest.questId)
      end
    end,
  },
  ["StartQuestBelowRequirements"] = {
    message = function(quest, recsResult)
      return "You do not meet the recommended criteria to start this quest.\n"..
             "Accept anyway?"
    end,
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function() end, -- Need an empty function to trigger the OnYes handler
  },
  ["DeleteCatalogItem"] = {
    message = function(catalogItem)
      return "Are you sure you want to delete\n"..
             "\"%s\"?", catalogItem.quest.name
    end,
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function(catalogItem)
      addon.QuestCatalog:Delete(catalogItem.quest.questId)
      addon.Logger:Warn("Catalog item deleted: %s", catalogItem.quest.name)
    end,
  },
  ["ExitDraft"] = {
    message = "You have unsaved changes.\n"..
              "Would you like to save?",
    yesText = "Discard",
    noText = "Cancel",
    otherText = "Save",
    yesHandler = function()
      addon.MainMenu:NavToMenuScreen("QuestDraftListMenu")
    end,
    otherHandler = function(saveFunction)
      saveFunction()
      addon.MainMenu:NavToMenuScreen("QuestDraftListMenu")
    end,
  },
  ["DeleteDraft"] = {
    message = function(draftId, draftName)
      return "Are you sure you want to delete\n"..
             "\"%s\"?", draftName
    end,
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function(draftId, draftName)
      addon.QuestDrafts:Delete(draftId)
      addon.Logger:Warn("Draft deleted: %s", draftName)
    end,
  },
  ["DeleteArchive"] = {
    message = function(quest)
      return "Are you sure you want to delete \"%s\"?\n"..
             "This will delete the quest entirely from your archive, and PMQ will forget you ever had it!", quest.name
    end,
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function(quest)
      QuestArchive:Delete(quest.questId)
      addon.Logger:Warn("Quest removed from archive: %s", quest.name)
    end,
  },
  ["ResetArchive"] = {
    message = "Are you sure you want to reset your quest archive?\n"..
              "This will remove all quests from your archive, and PMQ will forget you ever had them!",
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function()
      QuestArchive:DeleteAll()
      addon:PlaySound("QuestAbandoned")
      addon.Logger:Warn("Quest Archive cleared")
    end,
  },
  ["ResetSaveData"] = {
    message = "Are you sure you want to clear all save data?\n"..
              "This will remove all drafts, quests, quest progress, and settings from PMQ.\n"..
              "Once you click, there is no going back! This cannot be undone!",
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function()
      addon.SaveData:ClearAll()
      addon.SaveData:ClearAll(true)
      addon.G.ReloadUI()
    end,
  },
  ["RenameDemoCopy"] = {
    message = "Enter a name for your quest draft.",
    editBox = function(demo)
      return "Copy of "..demo.demoName, true
    end,
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function(demo, text)
      addon.QuestDemos:CopyToDrafts(demo.demoId, text)
      addon.Logger:Info("Demo quest copied to drafts.")
      addon.MainMenu:NavToMenuScreen("QuestDraftListMenu")
    end,
  },
  ["ResetCatalog"] = {
    message = "Remove all quests from your catalog?",
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function()
      addon.QuestCatalog:DeleteAll()
      addon:PlaySound("QuestAbandoned")
      addon.Logger:Warn("Quest Catalog cleared")
    end,
  },
  ["ResetDrafts"] = {
    message = "Delete all quest drafts?\nThis will delete all drafts shared between all of your characters!",
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function()
      addon.QuestDrafts:DeleteAll()
      addon:PlaySound("QuestAbandoned")
      addon.Logger:Warn("Quest Drafts cleared")
    end,
  },
  ["NewLocation"] = {
    message = "Enter the name of your location.",
    editBox = function(location)
      return "New Location", true
    end,
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function(location, text)
      location = addon:CopyTable(location)
      location.name = text
      addon.Locations:Save(location)
    end,
  },
  ["UpdateLocation"] = {
    message = "Update the zone, subzone, and coordinates for this location?",
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function(location)
      local playerLocation = addon:GetPlayerLocation()
      location.zone = playerLocation.zone
      location.subZone = playerLocation.subZone
      location.x = playerLocation.x
      location.y = playerLocation.y
      addon.Locations:Save(location)
    end,
  },
  ["RenameLocation"] = {
    message = "Enter the new name of your location.",
    editBox = function(location)
      return location.name, true
    end,
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function(location, text)
      location.name = text
      addon.Locations:Save(location)
    end,
  },
  ["DeleteLocation"] = {
    message = "Delete this location?",
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function(location)
      addon.Locations:Delete(location.locationId)
    end,
  },
  ["ResetLocations"] = {
    message = "Are you sure you want to delete all locations?",
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function(location)
     addon.Locations:DeleteAll()
    end,
  },
  ["EditConfigValue"] = {
    message = function(configItem)
      return "Edit value for:\n"..configItem.name
    end,
    editBox = function(configItem)
      return tostring(configItem.value), true
    end,
    yesText = "Save",
    noText = "Discard",
    yesHandler = function(configItem, text)
      local v = addon.Config:SaveValue(configItem.name, text)
      if v then
        addon.Logger:Warn("Config value updated: %s = %s", configItem.name, tostring(v))
      end
    end,
  },
  ["ResetAllConfig"] = {
    message = "Reset all config values to PMQ defaults?",
    yesText = "OK",
    noText = "Cancel",
    yesHandler = function()
      addon.Config:ResetAll()
      addon.Logger:Warn("Config values reset")
    end,
  },
  ["SetLogLevel"] = {
    message = function(logName)
      return "Set log level for:\n"..logName
    end,
    editBox = function(logName, logLevelName)
      return logLevelName, true
    end,
    yesText = "Save",
    noText = "Discard",
    yesHandler = function(logName, logLevelName, text)
      local v = addon:SetUserLogLevel(logName, text)
      if v then
        addon.Logger:Warn("Set log level for %s to %s.", logName, text)
      end
    end,
  },
}