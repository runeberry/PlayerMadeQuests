local _, addon = ...

--- These are the default values for every config item supported by PMQ.
addon.defaultSettings = {
  --- The version and branch of the addon.
  --- Set branch to false for a production release.
  VERSION = 103,
  BRANCH = "beta",
  --- Hack for unit testing.
  --- Enable this to avoid building UI elements when the addon is loaded.
  AVOID_BUILDING_UI = false,
  --- Defines the core method used for logging.
  --- See available options under Logger.lua -> addon.LogMode
  GLOBAL_LOG_MODE = "pretty",
  --- All logs below this level will be hidden across all Loggers.
  --- See available options under Logger.lua -> addon.LogLevel
  GLOBAL_LOG_FILTER = "info",
  --- The amount of time in seconds between checks for the player's location
  --- when location polling is enabled.
  PLAYER_LOCATION_INTERVAL = 1.0,
  --- The amount of time in seconds that a player's location should be cached.
  PLAYER_LOCATION_TTL = 0.5,
  --- Enable this to suppress all print output while still calling the print function.
  --- Not for use in-game. Reserved for unit testing.
  SILENT_PRINT = false,
  --- Show this MainMenu screen immediately when the addon loads.
  --- Set to false to not show any menu on startup.
  START_MENU = false,
  --- Enable this for detailed logs on Repository transactions.
  --- Disabled by default because it can be quite verbose.
  TRANSACTION_LOGS = false,
  --- Replace WoW color codes with ANSI color codes when printing logs to console.
  --- Not for use in-game. Reserved for unit testing.
  USE_ANSI_COLORS = false,
  --- Enable this to reflect all outbound messages back on the player character.
  --- The sender's name will be listed as "*yourself*"
  USE_INTERNAL_MESSAGING = false,
}