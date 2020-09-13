local _, addon = ...

--[[
  Archived quest model:
  -- Same as QuestLog, for now
--]]

addon.QuestArchive = addon:NewRepository("Archive", "questId")
addon.QuestArchive:SetSaveDataSource("QuestArchive")
addon.QuestArchive:EnableWrite(true)
addon.QuestArchive:EnableCompression(true)
addon.QuestArchive:EnableTimestamps(true)