local _, addon = ...

local migrations = {}

--- Adds a function to run as a "migration". This function will be executed on startup only
--- if the character's saved AddonVersion is earlier than the specified version.
function addon:NewMigration(version, fn)
  migrations[#migrations+1] = { version = version, fn = fn }
end

function addon:RunMigrations()
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
  for _, migration in ipairs(migrations) do
    -- Only run migration functions if:
    -- * The character's last-run version is lower than the migration's designated version
    if fromMigrationVersion < migration.version and migration.version <= addon.VERSION then
      migrationApplied = true
      addon.Logger:Trace("Applying migration: %i -> %i", fromMigrationVersion, migration.version)
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
    addon.Logger:Error(err)
    addon.Logger:Error("Please report this error to the developers!")
    return
  end

  addon.SaveData:Save("AddonVersion", addon.VERSION)
  addon.SaveData:Save("AddonBranch", addon.BRANCH)
  addon.Logger:Info("Data successfully updated to version %s.", addon:GetVersionText())
end