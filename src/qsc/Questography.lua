local _, addon = ...
addon:traceFile("Questography.lua")

addon.Questography = {}
addon.QuestographyStatus = {
  Draft = "Draft",
  Alpha = "Alpha",
  Beta = "Beta",
  Published = "Published",
  Deprecated = "Deprecated",
}