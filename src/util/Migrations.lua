local _, addon = ...
local logger = addon.Logger:NewLogger("Migration", addon.LogLevel.info)

local addonMigrations = {}
local questMigrations = {}

--------------------
-- Public methods --
--------------------

--- Adds a function to run as a "migration". This function will be executed on startup only
--- if the character's saved AddonVersion is earlier than the specified version.
function addon:NewAddonMigration(version, fn)
  addonMigrations[#addonMigrations+1] = { version = version, fn = fn }
end

--- Adds a function to run as a "migration" on every quest currently saved to this character.

function addon:NewQuestMigration(version, fn)
  questMigrations[#questMigrations+1] = { version = version, fn = fn }
end

--- Migrates any quest object from its compile-time version to the current addon version.
--- The quest object is modified in-place.
--- @param quest table - a quest to migrate (modified in-place)
--- @return boolean - True if the migration was successful, false otherwise
--- @return table | string - The updated quest if successful, err message if failed
--- @return number - Number of migrations successfully applied
function addon:MigrateQuest(quest)
  local questVersion
  if quest.metadata and quest.metadata.addonVersion then
    questVersion = quest.metadata.addonVersion
  else
    -- Quest version is older than v0.2.0-beta, run all migrations
    questVersion = 0
  end

  if questVersion >= addon.VERSION then
    -- Quest is already current-version, (or somehow future-version?), nothing to update
    return true, quest, 0
  end

  local ok, err
  local numMigrations = 0
  local fromMigrationVersion = questVersion
  for _, migration in ipairs(questMigrations) do
    -- Only run the migration if:
    -- * The quest's version is less than the migration's specified version
    -- * The migration's specified version is <= the current addon version
    if fromMigrationVersion < migration.version and migration.version <= addon.VERSION then
      logger:Trace("Applying quest migration: %i -> %i", fromMigrationVersion, migration.version)
      ok, err = pcall(migration.fn, quest)
      if not ok then
        err = err or "Unknown error"
        -- Include the quest's original saved version in the error message here to help with troubleshooting
        return false, string.format("Quest migration (%i -> %i) failed: %s", questVersion, migration.version, err), numMigrations
      end
      -- Step up the migrated version each time one is applied
      fromMigrationVersion = migration.version
      numMigrations = numMigrations + 1
    end
  end

  -- Upon successful migration, update the quest's metadata
  if not quest.metadata then quest.metadata = {} end
  quest.metadata.addonVersion = addon.VERSION
  return true, quest, numMigrations
end

----------------------
-- Lifecycle events --
----------------------

function addon:RunAddonMigrations()
  if addon.IsFirstRun then
    -- Don't perform any data migrations on a fresh save file
    addon.SaveData:Save("AddonVersion", addon.VERSION)
    addon.SaveData:Save("AddonBranch", addon.BRANCH)
    return
  end

  local lastVersion = addon.SaveData:Load("AddonVersion")

  -- AddonVersion was not saved until AFTER version 104 (v0.1.4-beta), so assume version 0 if this value is missing
  lastVersion = lastVersion or 0

  -- Don't perform any migrations if this addon version has already been run
  if lastVersion >= addon.VERSION then return end

  local ok, err, migrationApplied
  local fromMigrationVersion = lastVersion
  for _, migration in ipairs(addonMigrations) do
    -- Only run migration functions if:
    -- * The character's last-run version is lower than the migration's designated version
    if fromMigrationVersion < migration.version and migration.version <= addon.VERSION then
      migrationApplied = true
      logger:Trace("Applying migration: %i -> %i", fromMigrationVersion, migration.version)
      ok, err = pcall(migration.fn)
      if not ok then
        err = err or "Unknown error"
        -- Include the player's last saved version in the error message here to help with troubleshooting
        err = string.format("Data migration (%i -> %i) failed: %s", lastVersion, migration.version, err)
        break
      end
      fromMigrationVersion = migration.version
    end
  end

  if migrationApplied and not ok then
    if not ok then
      logger:Error(err)
      logger:Error("Please report this error to the developers!")
    else
      addon.Logger:Info("Addon data updated to version %s.", addon:GetVersionText())
    end
  end

  -- Always write current version and branch to save file, even if no migrations were performed
  addon.SaveData:Save("AddonVersion", addon.VERSION)
  addon.SaveData:Save("AddonBranch", addon.BRANCH)
end

function addon:RunQuestMigrations()
  local quests = addon.QuestLog:FindAll()
  local numQuestsMigrated, numQuestsFailed = 0, 0
  for _, quest in ipairs(quests) do
    local ok, err, numMigrations = addon:MigrateQuest(quest)
    if not ok then
      logger:Error(err)
      numQuestsFailed = numQuestsFailed + 1
    elseif numMigrations > 0 then
      addon.QuestLog:Save(quest)
      numQuestsMigrated = numQuestsMigrated + 1
    end
  end

  quests = addon.QuestArchive:FindAll()
  for _, quest in ipairs(quests) do
    local ok, err, numMigrations = addon:MigrateQuest(quest)
    if not ok then
      logger:Error(err)
      numQuestsFailed = numQuestsFailed + 1
    elseif numMigrations > 0 then
      addon.QuestArchive:Save(quest)
      numQuestsMigrated = numQuestsMigrated + 1
    end
  end

  if numQuestsMigrated > 0 or numQuestsFailed > 0 then
    addon.Logger:Info("Quests updated to %s. (%i updated, %i failed)",
      addon:GetVersionText(), numQuestsMigrated, numQuestsFailed)
  end
end