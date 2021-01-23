local _, addon = ...

--- These are the default values for every config item supported by PMQ.
addon.defaultSettings = {
  --- The character set to use for escape codes (string coloring).
  CHARSET = "WOW",
  --- Disable this to skip the GUI building events of the Lifecycle.
  --- Useful for unit testing.
  ENABLE_GUI = true,
  --- Enable this to reflect all outbound messages back on the player character.
  --- The sender's name will be listed as "*yourself*"
  ENABLE_SELF_MESSAGING = false,
  --- Enable this for detailed logs on Repository transactions.
  --- Disabled by default because it can be quite verbose.
  ENABLE_TRANSACTION_LOGS = false,
  --- Feature flag: Count player pet kills towards kill objectives.
  FEATURE_PET_KILLS = true,
  --- Applies a global chat filter that suppresses 'player not online' messages.
  --- Disabling this will result in some spam from the addon.
  FILTER_OFFLINE_MESSAGE = true,
  --- All logs below this level will be hidden across all Loggers.
  --- See available options under Logger.lua -> addon.LogLevel
  GLOBAL_LOG_FILTER = "info",
  -- Settings for various in-game notifications.
  NOTIFY_COMPLETE_AUTHOR = true,
  NOTIFY_COMPLETE_SHARER = true,
  NOTIFY_COMPLETE_BULK = true,
  NOTIFY_VERSION_UPDATE = true,
  --- How often (# of items) a progress log should be printed when scanning for items.
  ITEM_SCAN_LOG_INTERVAL = 500,
  --- The amount of time in seconds to wait to see if an item comes back
  --- from GetItemInfo()
  ITEM_SCAN_TIMEOUT = 1,
  --- The amount of time in seconds between checks for the player's location
  --- when location polling is enabled.
  PLAYER_LOCATION_INTERVAL = 1.0,
  --- The amount of time in seconds that a player's location should be cached.
  PLAYER_LOCATION_TTL = 0.5,
  --- How many spells should be scanned each interval when scanning for spells?
  --- Higher number scans faster, but impacts performance.
  SPELL_SCAN_INTENSITY = 5,
  --- How often (# of spells) a progress log should be printed when scanning for spells.
  SPELL_SCAN_LOG_INTERVAL = 5000,
  --- Show this MainMenu screen immediately when the addon loads.
  --- Set to an empty string to not show any menu on startup.
  START_MENU = "",
  --- Links to external PMQ references.
  URL_DISCORD = "https://discord.gg/HBsNJTY",
  URL_GITHUB = "https://github.com/runeberry/PlayerMadeQuests",
  URL_WIKI = "https://pmq.runeberry.com",
  --- The amount of time in seconds that "known version" info should be cached
  --- for the purpose of notifying the player of version updates.
  VERSION_INFO_TTL = 3 * 86400, -- 3 days

  Logging = {},
  FrameData = {},
}