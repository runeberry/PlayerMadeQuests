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
  --- All logs below this level will be hidden across all Loggers.
  --- See available options under Logger.lua -> addon.LogLevel
  GLOBAL_LOG_FILTER = "info",
  --- Enable version update notifications whenever a newer version
  --- of the addon is detected.
  NOTIFY_VERSION_UPDATE = true,
  --- The amount of time in seconds between checks for the player's location
  --- when location polling is enabled.
  PLAYER_LOCATION_INTERVAL = 1.0,
  --- The amount of time in seconds that a player's location should be cached.
  PLAYER_LOCATION_TTL = 0.5,
  --- Show this MainMenu screen immediately when the addon loads.
  --- Set to an empty string to not show any menu on startup.
  START_MENU = "",
  --- The amount of time in seconds that "known version" info should be cached
  --- for the purpose of notifying the player of version updates.
  VERSION_INFO_TTL = 3 * 86400, -- 3 days

  Logging = {},
  FrameData = {},
}