local _, addon = ...
local MessageEvents, MessageDistribution, MessagePriority = addon.MessageEvents, addon.MessageDistribution, addon.MessagePriority
local IsInGroup, IsInRaid = addon.G.IsInGroup, addon.G.IsInRaid
local time = addon.G.time

--- Only notify player of version updates once per session
local hasNotifiedVersion
local updateNotificationsEnabled

-- Time in seconds to post back to the player that "no new version has been found"
-- Not truly a timeout, just a feedback device for players
local updateResponseTimeout = 3

-- Throttle version checks so they can't be spammed
local lastVersionCheck = 0
local versionCheckThrottle = 10
local known

-- Is this version newer than the highest version we already know about?
local function isNewerThanKnown(version, branch, timestamp)
  if not known then return true end -- Don't know any other version so... yeah, this is newer
  return version > known.VERSION or timestamp > known.TIMESTAMP
end

-- Is this version newer than our addon? Equal versions return false.
local function isNewerThanAddon(version, branch, timestamp)
  return version > addon.VERSION or timestamp > addon.TIMESTAMP
end

-- Is this version older than our addon? Equal versions return false.
local function isOlderThanAddon(version, branch, timestamp)
  return version < addon.VERSION or timestamp < addon.TIMESTAMP
end

local function saveVersionInfo(version, branch, timestamp)
  known = known or {}
  known.VERSION = version
  known.BRANCH = branch
  known.TIMESTAMP = timestamp
  known.at = time() -- Remember when we learned about this version so we can expire this knowledge
  addon.SaveData:Save("KnownVersionInfo", known, true)
end

local function loadVersionInfo()
  local kvi = addon.SaveData:Load("KnownVersionInfo", true)

  if not kvi or not kvi.VERSION or not kvi.TIMESTAMP then
    -- Nothing is saved, or invalid data is saved
    return
  elseif not isNewerThanAddon(kvi.VERSION, kvi.BRANCH, kvi.TIMESTAMP) then
    -- The version we know about is now older than our current version
    -- This could be true right after you update
    addon.SaveData:Clear("KnownVersionInfo", true)
    return
  end

  local ttl = addon.Config:GetValue("VERSION_INFO_TTL")
  local expires = kvi.at + ttl
  if time() > expires then
    -- Cached version info is expired, fuhgeddaboutit
    addon.SaveData:Clear("KnownVersionInfo", true)
    return
  end

  -- If we made it this far, this is relevant info we should care about
  known = kvi
end

local function notifyUpdate(version, branch, timestamp)
  if updateNotificationsEnabled and not hasNotifiedVersion then
    local newVersionText = addon:GetVersionText(version, branch)
    addon.Logger:Warn("A new version of PMQ is available (%s).", newVersionText)
    hasNotifiedVersion = true
  end
end

local function checkAndNotify(version, branch, timestamp)
  if isNewerThanAddon(version, branch, timestamp) and isNewerThanKnown(version, branch, timestamp) then
    saveVersionInfo(version, branch, timestamp)
    notifyUpdate(version, branch, timestamp)
  end
end

local function checkAndNotifyManual(version, branch, timestamp)
  if isNewerThanAddon(version, branch, timestamp) then
    if isNewerThanKnown(version, branch, timestamp) then
      saveVersionInfo(version, branch, timestamp)
    end
    notifyUpdate(version, branch, timestamp)
  end
end

local function tellVersion(event, distro, target)
  MessageEvents:Publish(event,
    { distribution = distro, target = target, priority = MessagePriority.Bulk },
    addon.VERSION, addon.BRANCH, addon.TIMESTAMP)
end

local function broadcastVersion(manual)
  local event
  if manual then
    event = "AddonVersionRequestManual"
  else
    event = "AddonVersionRequest"
  end

  tellVersion(event, MessageDistribution.Yell)
  tellVersion(event, MessageDistribution.Guild)

  if IsInRaid() then
    tellVersion(event, MessageDistribution.Raid)
  elseif IsInGroup() then
    tellVersion(event, MessageDistribution.Party)
  end
end

function addon:CheckForUpdates()
  local currentTime = time()
  if currentTime - lastVersionCheck < versionCheckThrottle then
    addon.Logger:Trace("Version has been checked too recently")
    return
  end
  lastVersionCheck = currentTime

  addon.Logger:Info("Checking nearby players for updates...")

  addon.Ace:ScheduleTimer(function()
    if not hasNotifiedVersion then
      addon.Logger:Info("No updates found.")
    end
  end, updateResponseTimeout)

  -- Reset the notify flag, since this is a manual check we're expecting another response
  hasNotifiedVersion = false
  broadcastVersion(true)
end

addon:OnBackendStart(function()
  loadVersionInfo()
  updateNotificationsEnabled = addon.Config:GetValue("NOTIFY_VERSION_UPDATE")

  MessageEvents:Subscribe("AddonVersionRequest", function(distribution, sender, version, branch, timestamp)
    checkAndNotify(version, branch, timestamp)
    if isOlderThanAddon(version, branch, timestamp) then
      -- Only respond if the requestor's version is older than our addon
      tellVersion("AddonVersionResponse", MessageDistribution.Whisper, sender)
    end
  end)
  MessageEvents:Subscribe("AddonVersionResponse", function(distribution, sender, version, branch, timestamp)
    checkAndNotify(version, branch, timestamp)
  end)
  MessageEvents:Subscribe("AddonVersionRequestManual", function(distribution, sender, version, branch, timestamp)
    checkAndNotify(version, branch, timestamp)
    if isOlderThanAddon(version, branch, timestamp) then
      -- Only respond if the requestor's version is older than our addon
      tellVersion("AddonVersionResponseManual", MessageDistribution.Whisper, sender)
    end
  end)
  MessageEvents:Subscribe("AddonVersionResponseManual", function(distribution, sender, version, branch, timestamp)
    -- This is the only event to use the "Manual" version of checkAndNotify.
    -- It has different rules for notifying the player because this only occurs when a version check
    -- is triggered manually (by the CLI or a button click)
    checkAndNotifyManual(version, branch, timestamp)
  end)

  -- The following events will automatically trigger a version check
  addon.GameEvents:Subscribe("GROUP_JOINED", broadcastVersion)
  addon:OnAddonReady(broadcastVersion)
  MessageEvents:Subscribe("QuestInvite", function(distribution, sender)
    tellVersion("AddonVersionRequest", MessageDistribution.Whisper, sender)
  end)
end)