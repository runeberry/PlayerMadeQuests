local _, addon = ...
addon:traceFile("QuestCatalog.lua")

addon.QuestCatalog = {}
addon.QuestCatalogStatus = {
  Invited = "Invited",
  Accepted = "Accepted",
  Abandoned = "Abandoned",
  Completed = "Completed",
  Archived = "Archived",
}