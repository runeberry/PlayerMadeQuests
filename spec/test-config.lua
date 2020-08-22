--- This is the default addon config for every addon built with addon-builder
return {
  VERSION = 1,
  BRANCH = "test",
  -- todo: need better mocking system for UI, but suppress errors for now
  AVOID_BUILDING_UI = true,
  GLOBAL_LOG_MODE = "pretty",
  GLOBAL_LOG_FILTER = "silent",
  PLAYER_LOCATION_INTERVAL = 1.0,
  PLAYER_LOCATION_TTL = 0.5,
  SILENT_PRINT = false,
  START_MENU = "",
  TRANSACTION_LOGS = false,
  USE_ANSI_COLORS = true,
  USE_INTERNAL_MESSAGING = true,

  Logging = {},
  FrameData = {},
}