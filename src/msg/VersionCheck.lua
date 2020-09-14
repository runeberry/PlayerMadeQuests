local _, addon = ...
local MessageEvents, MessageDistribution, MessagePriority = addon.MessageEvents, addon.MessageDistribution, addon.MessagePriority
local IsInGroup, IsInRaid = addon.G.IsInGroup, addon.G.IsInRaid
local time = addon.G.time

--- Only notify player of version updates once per session
local hasNotifiedVersion
local updateNotificationsEnabled
local knownVersionInfo

-- Time in seconds to post back to the player that "no new version has been found"
-- Not truly a timeout, just a feedback device for players
local updateResponseTimeout = 3

local function saveVersionInfo(version, branch)
  version = version or addon.VERSION
  branch = branch or addon.BRANCH

  knownVersionInfo.version = version
  knownVersionInfo.branch = branch
  knownVersionInfo.date = time()
  addon.SaveData:Save("KnownVersionInfo", knownVersionInfo, true)
end

local function loadVersionInfo()
  knownVersionInfo = addon.SaveData:LoadTable("KnownVersionInfo", true)

  if not knownVersionInfo.version then
    -- Nothing is saved, save current addon version as highest known version
    saveVersionInfo()
    return
  end

  local ttl = addon.Config:GetValue("VERSION_INFO_TTL")
  local expires = knownVersionInfo.date + ttl
  if time() > expires then
    -- Cached version info is expired, overwrite w/ current version info
    saveVersionInfo()
  end
end

local function notifyVersion(version, branch)
  if version > knownVersionInfo.version then
    saveVersionInfo(version, branch)
    if updateNotificationsEnabled and not hasNotifiedVersion then
      local newVersionText = addon:GetVersionText(version, branch)
      addon.Logger:Warn("A new version of PMQ is available (%s).", newVersionText)
      hasNotifiedVersion = true
    end
  end
end

local function tellVersion(event, distro, target)
  MessageEvents:Publish(event,
    { distribution = distro, target = target, priority = MessagePriority.Bulk },
    addon.VERSION, addon.BRANCH)
end

-- Set to "false" to allow another update notification to occur
-- Set to "true" to suppress update notifications for this session
function addon:SetUpdateCheckFlag(flag)
  hasNotifiedVersion = flag
end

function addon:BroadcastAddonVersion(notify)
  if notify then
    addon.Logger:Info("Checking nearby players for newer versions...")

    addon.Ace:ScheduleTimer(function()
      if not hasNotifiedVersion then
        addon.Logger:Info("No updates found.")
      end
    end, updateResponseTimeout)
  end

  tellVersion("AddonVersionRequest", MessageDistribution.Yell)
  tellVersion("AddonVersionRequest", MessageDistribution.Guild)

  if IsInRaid() then
    tellVersion("AddonVersionRequest", MessageDistribution.Raid)
  elseif IsInGroup() then
    tellVersion("AddonVersionRequest", MessageDistribution.Party)
  end
end

function addon:RequestAddonVersion(distro, target)
  tellVersion("AddonVersionRequest", distro, target)
end

addon:OnBackendStart(function()
  loadVersionInfo()
  updateNotificationsEnabled = addon.Config:GetValue("NOTIFY_VERSION_UPDATE")

  MessageEvents:Subscribe("AddonVersionRequest", function(distribution, sender, version, branch)
    notifyVersion(version, branch)
    tellVersion("AddonVersionResponse", MessageDistribution.Whisper, sender)
  end)
  MessageEvents:Subscribe("AddonVersionResponse", function(distribution, sender, version, branch)
    notifyVersion(version, branch)
  end)
end)

addon:OnAddonReady(function()
  addon:BroadcastAddonVersion()
end)