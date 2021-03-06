local _, addon = ...

addon.GameEventsList = {
  "ACTIONBAR_HIDEGRID",
  "ACTIONBAR_PAGE_CHANGED",
  "ACTIONBAR_SHOW_BOTTOMLEFT",
  "ACTIONBAR_SHOWGRID",
  "ACTIONBAR_SLOT_CHANGED",
  "ACTIONBAR_UPDATE_COOLDOWN",
  "ACTIONBAR_UPDATE_STATE",
  "ACTIONBAR_UPDATE_USABLE",
  "PET_BAR_UPDATE",
  "UPDATE_BONUS_ACTIONBAR",
  "ADDON_LOADED",
  "ADDONS_UNLOADING",
  "SAVED_VARIABLES_TOO_LARGE",
  "AREA_POIS_UPDATED",
  "AUCTION_BIDDER_LIST_UPDATE",
  "AUCTION_HOUSE_CLOSED",
  "AUCTION_HOUSE_DISABLED",
  "AUCTION_HOUSE_SCRIPT_DEPRECATED",
  "AUCTION_HOUSE_SHOW",
  "AUCTION_ITEM_LIST_UPDATE",
  "AUCTION_MULTISELL_FAILURE",
  "AUCTION_MULTISELL_START",
  "AUCTION_MULTISELL_UPDATE",
  "AUCTION_OWNED_LIST_UPDATE",
  "NEW_AUCTION_UPDATE",
  "BANK_BAG_SLOT_FLAGS_UPDATED",
  "BANKFRAME_CLOSED",
  "BANKFRAME_OPENED",
  "PLAYERBANKBAGSLOTS_CHANGED",
  "PLAYERBANKSLOTS_CHANGED",
  "SIMPLE_BROWSER_WEB_ERROR",
  "SIMPLE_BROWSER_WEB_PROXY_FAILED",
  "SIMPLE_CHECKOUT_CLOSED",
  "ALTERNATIVE_DEFAULT_LANGUAGE_CHANGED",
  "BN_CHAT_MSG_ADDON",
  "CHANNEL_COUNT_UPDATE",
  "CHANNEL_FLAGS_UPDATED",
  "CHANNEL_INVITE_REQUEST",
  "CHANNEL_LEFT",
  "CHANNEL_PASSWORD_REQUEST",
  "CHANNEL_ROSTER_UPDATE",
  "CHANNEL_UI_UPDATE",
  "CHAT_COMBAT_MSG_ARENA_POINTS_GAIN",
  "CHAT_MSG_ACHIEVEMENT",
  "CHAT_MSG_ADDON",
  "CHAT_MSG_ADDON_LOGGED",
  "CHAT_MSG_AFK",
  "CHAT_MSG_BG_SYSTEM_ALLIANCE",
  "CHAT_MSG_BG_SYSTEM_HORDE",
  "CHAT_MSG_BG_SYSTEM_NEUTRAL",
  "CHAT_MSG_BN",
  "CHAT_MSG_BN_INLINE_TOAST_ALERT",
  "CHAT_MSG_BN_INLINE_TOAST_BROADCAST",
  "CHAT_MSG_BN_INLINE_TOAST_BROADCAST_INFORM",
  "CHAT_MSG_BN_INLINE_TOAST_CONVERSATION",
  "CHAT_MSG_BN_WHISPER",
  "CHAT_MSG_BN_WHISPER_INFORM",
  "CHAT_MSG_BN_WHISPER_PLAYER_OFFLINE",
  "CHAT_MSG_CHANNEL",
  "CHAT_MSG_CHANNEL_JOIN",
  "CHAT_MSG_CHANNEL_LEAVE",
  "CHAT_MSG_CHANNEL_LIST",
  "CHAT_MSG_CHANNEL_NOTICE",
  "CHAT_MSG_CHANNEL_NOTICE_USER",
  "CHAT_MSG_COMBAT_FACTION_CHANGE",
  "CHAT_MSG_COMBAT_HONOR_GAIN",
  "CHAT_MSG_COMBAT_MISC_INFO",
  "CHAT_MSG_COMBAT_XP_GAIN",
  "CHAT_MSG_COMMUNITIES_CHANNEL",
  "CHAT_MSG_CURRENCY",
  "CHAT_MSG_DND",
  "CHAT_MSG_EMOTE",
  "CHAT_MSG_FILTERED",
  "CHAT_MSG_GUILD",
  "CHAT_MSG_GUILD_ACHIEVEMENT",
  "CHAT_MSG_GUILD_ITEM_LOOTED",
  "CHAT_MSG_IGNORED",
  "CHAT_MSG_INSTANCE_CHAT",
  "CHAT_MSG_INSTANCE_CHAT_LEADER",
  "CHAT_MSG_LOOT",
  "CHAT_MSG_MONEY",
  "CHAT_MSG_MONSTER_EMOTE",
  "CHAT_MSG_MONSTER_PARTY",
  "CHAT_MSG_MONSTER_SAY",
  "CHAT_MSG_MONSTER_WHISPER",
  "CHAT_MSG_MONSTER_YELL",
  "CHAT_MSG_OFFICER",
  "CHAT_MSG_OPENING",
  "CHAT_MSG_PARTY",
  "CHAT_MSG_PARTY_LEADER",
  "CHAT_MSG_PET_BATTLE_COMBAT_LOG",
  "CHAT_MSG_PET_BATTLE_INFO",
  "CHAT_MSG_PET_INFO",
  "CHAT_MSG_RAID",
  "CHAT_MSG_RAID_BOSS_EMOTE",
  "CHAT_MSG_RAID_BOSS_WHISPER",
  "CHAT_MSG_RAID_LEADER",
  "CHAT_MSG_RAID_WARNING",
  "CHAT_MSG_RESTRICTED",
  "CHAT_MSG_SAY",
  "CHAT_MSG_SKILL",
  "CHAT_MSG_SYSTEM",
  "CHAT_MSG_TARGETICONS",
  "CHAT_MSG_TEXT_EMOTE",
  "CHAT_MSG_TRADESKILLS",
  "CHAT_MSG_WHISPER",
  "CHAT_MSG_WHISPER_INFORM",
  "CHAT_MSG_YELL",
  "CHAT_SERVER_DISCONNECTED",
  "CHAT_SERVER_RECONNECTED",
  "CLEAR_BOSS_EMOTES",
  "LANGUAGE_LIST_CHANGED",
  "QUEST_BOSS_EMOTE",
  "RAID_BOSS_EMOTE",
  "RAID_BOSS_WHISPER",
  "RAID_INSTANCE_WELCOME",
  "UPDATE_CHAT_COLOR",
  "UPDATE_CHAT_COLOR_NAME_BY_CLASS",
  "UPDATE_CHAT_WINDOWS",
  "UPDATE_FLOATING_CHAT_WINDOWS",
  "CINEMATIC_START",
  "CINEMATIC_STOP",
  "HIDE_SUBTITLE",
  "PLAY_MOVIE",
  "AVATAR_LIST_UPDATED",
  "CLUB_ADDED",
  "CLUB_ERROR",
  "CLUB_INVITATION_ADDED_FOR_SELF",
  "CLUB_INVITATION_REMOVED_FOR_SELF",
  "CLUB_INVITATIONS_RECEIVED_FOR_CLUB",
  "CLUB_MEMBER_ADDED",
  "CLUB_MEMBER_PRESENCE_UPDATED",
  "CLUB_MEMBER_REMOVED",
  "CLUB_MEMBER_ROLE_UPDATED",
  "CLUB_MEMBER_UPDATED",
  "CLUB_MESSAGE_ADDED",
  "CLUB_MESSAGE_HISTORY_RECEIVED",
  "CLUB_MESSAGE_UPDATED",
  "CLUB_REMOVED",
  "CLUB_REMOVED_MESSAGE",
  "CLUB_SELF_MEMBER_ROLE_UPDATED",
  "CLUB_STREAM_ADDED",
  "CLUB_STREAM_REMOVED",
  "CLUB_STREAM_SUBSCRIBED",
  "CLUB_STREAM_UNSUBSCRIBED",
  "CLUB_STREAM_UPDATED",
  "CLUB_STREAMS_LOADED",
  "CLUB_TICKET_CREATED",
  "CLUB_TICKET_RECEIVED",
  "CLUB_TICKETS_RECEIVED",
  "CLUB_UPDATED",
  "INITIAL_CLUBS_LOADED",
  "STREAM_VIEW_MARKER_UPDATED",
  "COMBAT_LOG_EVENT",
  "COMBAT_LOG_EVENT_UNFILTERED",
  "COMBAT_TEXT_UPDATE",
  "COMMENTATOR_ENTER_WORLD",
  "COMMENTATOR_IMMEDIATE_FOV_UPDATE",
  "COMMENTATOR_MAP_UPDATE",
  "COMMENTATOR_PLAYER_NAME_OVERRIDE_UPDATE",
  "COMMENTATOR_PLAYER_UPDATE",
  "COMPACT_UNIT_FRAME_PROFILES_LOADED",
  "CONSOLE_CLEAR",
  "CONSOLE_COLORS_CHANGED",
  "CONSOLE_FONT_SIZE_CHANGED",
  "CONSOLE_LOG",
  "CONSOLE_MESSAGE",
  "CVAR_UPDATE",
  "GLUE_CONSOLE_LOG",
  "TOGGLE_CONSOLE",
  "BAG_CLOSED",
  "BAG_NEW_ITEMS_UPDATED",
  "BAG_OPEN",
  "BAG_OVERFLOW_WITH_FULL_INVENTORY",
  "BAG_SLOT_FLAGS_UPDATED",
  "BAG_UPDATE",
  "BAG_UPDATE_COOLDOWN",
  "BAG_UPDATE_DELAYED",
  "EQUIP_BIND_TRADEABLE_CONFIRM",
  "INVENTORY_SEARCH_UPDATE",
  "ITEM_LOCK_CHANGED",
  "ITEM_LOCKED",
  "ITEM_UNLOCKED",
  "CRAFT_CLOSE",
  "CRAFT_SHOW",
  "CRAFT_UPDATE",
  "PLAYER_MONEY",
  "BATTLE_PET_CURSOR_CLEAR",
  "COMMUNITIES_STREAM_CURSOR_CLEAR",
  "CURSOR_UPDATE",
  "MOUNT_CURSOR_CLEAR",
  "AREA_SPIRIT_HEALER_IN_RANGE",
  "AREA_SPIRIT_HEALER_OUT_OF_RANGE",
  "CEMETERY_PREFERENCE_UPDATED",
  "CONFIRM_XP_LOSS",
  "CORPSE_IN_INSTANCE",
  "CORPSE_IN_RANGE",
  "CORPSE_OUT_OF_RANGE",
  "CORPSE_POSITION_UPDATE",
  "PLAYER_ALIVE",
  "PLAYER_DEAD",
  "PLAYER_SKINNED",
  "PLAYER_UNGHOST",
  "REQUEST_CEMETERY_LIST_RESPONSE",
  "RESURRECT_REQUEST",
  "SELF_RES_SPELL_CHANGED",
  "DUEL_FINISHED",
  "DUEL_INBOUNDS",
  "DUEL_OUTOFBOUNDS",
  "DUEL_REQUESTED",
  "BOSS_KILL",
  "DISABLE_LOW_LEVEL_RAID",
  "ENABLE_LOW_LEVEL_RAID",
  "ENCOUNTER_END",
  "ENCOUNTER_START",
  "INSTANCE_LOCK_START",
  "INSTANCE_LOCK_STOP",
  "INSTANCE_LOCK_WARNING",
  "RAID_TARGET_UPDATE",
  "UPDATE_INSTANCE_INFO",
  "BATTLETAG_INVITE_SHOW",
  "BN_BLOCK_FAILED_TOO_MANY",
  "BN_BLOCK_LIST_UPDATED",
  "BN_CHAT_WHISPER_UNDELIVERABLE",
  "BN_CONNECTED",
  "BN_CUSTOM_MESSAGE_CHANGED",
  "BN_CUSTOM_MESSAGE_LOADED",
  "BN_DISCONNECTED",
  "BN_FRIEND_ACCOUNT_OFFLINE",
  "BN_FRIEND_ACCOUNT_ONLINE",
  "BN_FRIEND_INFO_CHANGED",
  "BN_FRIEND_INVITE_ADDED",
  "BN_FRIEND_INVITE_LIST_INITIALIZED",
  "BN_FRIEND_INVITE_REMOVED",
  "BN_FRIEND_LIST_SIZE_CHANGED",
  "BN_INFO_CHANGED",
  "BN_REQUEST_FOF_SUCCEEDED",
  "FRIENDLIST_UPDATE",
  "IGNORELIST_UPDATE",
  "MUTELIST_UPDATE",
  "WHO_LIST_UPDATE",
  "GM_PLAYER_INFO",
  "ITEM_RESTORATION_BUTTON_STATUS",
  "PETITION_CLOSED",
  "PETITION_SHOW",
  "PLAYER_REPORT_SUBMITTED",
  "QUICK_TICKET_SYSTEM_STATUS",
  "QUICK_TICKET_THROTTLE_CHANGED",
  "UPDATE_WEB_TICKET",
  "DYNAMIC_GOSSIP_POI_UPDATED",
  "GOSSIP_CLOSED",
  "GOSSIP_CONFIRM",
  "GOSSIP_CONFIRM_CANCEL",
  "GOSSIP_ENTER_CODE",
  "GOSSIP_SHOW",
  "CLOSE_TABARD_FRAME",
  "DISABLE_DECLINE_GUILD_INVITE",
  "ENABLE_DECLINE_GUILD_INVITE",
  "GUILD_INVITE_CANCEL",
  "GUILD_INVITE_REQUEST",
  "GUILD_MOTD",
  "GUILD_PARTY_STATE_UPDATED",
  "GUILD_RANKS_UPDATE",
  "GUILD_REGISTRAR_CLOSED",
  "GUILD_REGISTRAR_SHOW",
  "GUILD_RENAME_REQUIRED",
  "GUILD_ROSTER_UPDATE",
  "GUILDTABARD_UPDATE",
  "OPEN_TABARD_FRAME",
  "PLAYER_GUILD_UPDATE",
  "REQUIRED_GUILD_RENAME_RESULT",
  "TABARD_CANSAVE_CHANGED",
  "TABARD_SAVE_PENDING",
  "INSTANCE_ENCOUNTER_ADD_TIMER",
  "INSTANCE_ENCOUNTER_ENGAGE_UNIT",
  "INSTANCE_ENCOUNTER_OBJECTIVE_COMPLETE",
  "INSTANCE_ENCOUNTER_OBJECTIVE_START",
  "INSTANCE_ENCOUNTER_OBJECTIVE_UPDATE",
  "ACTION_WILL_BIND_ITEM",
  "BIND_ENCHANT",
  "CHARACTER_ITEM_FIXUP_NOTIFICATION",
  "CONFIRM_BEFORE_USE",
  "DELETE_ITEM_CONFIRM",
  "END_BOUND_TRADEABLE",
  "GET_ITEM_INFO_RECEIVED",
  "ITEM_DATA_LOAD_RESULT",
  "MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL",
  "REPLACE_ENCHANT",
  "TRADE_REPLACE_ENCHANT",
  "USE_BIND_CONFIRM",
  "USE_NO_REFUND_CONFIRM",
  "ITEM_TEXT_BEGIN",
  "ITEM_TEXT_CLOSED",
  "ITEM_TEXT_READY",
  "ITEM_TEXT_TRANSLATION",
  "MODIFIER_STATE_CHANGED",
  "UPDATE_BINDINGS",
  "KNOWLEDGE_BASE_ARTICLE_LOAD_FAILURE",
  "KNOWLEDGE_BASE_ARTICLE_LOAD_SUCCESS",
  "KNOWLEDGE_BASE_QUERY_LOAD_FAILURE",
  "KNOWLEDGE_BASE_QUERY_LOAD_SUCCESS",
  "KNOWLEDGE_BASE_SERVER_MESSAGE",
  "KNOWLEDGE_BASE_SETUP_LOAD_FAILURE",
  "KNOWLEDGE_BASE_SETUP_LOAD_SUCCESS",
  "KNOWLEDGE_BASE_SYSTEM_MOTD_UPDATED",
  "LOADING_SCREEN_DISABLED",
  "LOADING_SCREEN_ENABLED",
  "CANCEL_LOOT_ROLL",
  "CONFIRM_LOOT_ROLL",
  "ITEM_PUSH",
  "LOOT_BIND_CONFIRM",
  "LOOT_CLOSED",
  "LOOT_HISTORY_AUTO_SHOW",
  "LOOT_HISTORY_FULL_UPDATE",
  "LOOT_HISTORY_ROLL_CHANGED",
  "LOOT_HISTORY_ROLL_COMPLETE",
  "LOOT_ITEM_AVAILABLE",
  "LOOT_ITEM_ROLL_WON",
  "LOOT_OPENED",
  "LOOT_READY",
  "LOOT_ROLLS_COMPLETE",
  "LOOT_SLOT_CHANGED",
  "LOOT_SLOT_CLEARED",
  "OPEN_MASTER_LOOT_LIST",
  "START_LOOT_ROLL",
  "TRIAL_CAP_REACHED_MONEY",
  "UPDATE_MASTER_LOOT_LIST",
  "LOSS_OF_CONTROL_ADDED",
  "LOSS_OF_CONTROL_UPDATE",
  "PLAYER_CONTROL_GAINED",
  "PLAYER_CONTROL_LOST",
  "EXECUTE_CHAT_LINE",
  "UPDATE_MACROS",
  "CLOSE_INBOX_ITEM",
  "MAIL_CLOSED",
  "MAIL_FAILED",
  "MAIL_INBOX_UPDATE",
  "MAIL_LOCK_SEND_ITEMS",
  "MAIL_SEND_INFO_UPDATE",
  "MAIL_SEND_SUCCESS",
  "MAIL_SHOW",
  "MAIL_SUCCESS",
  "MAIL_UNLOCK_SEND_ITEMS",
  "SEND_MAIL_COD_CHANGED",
  "SEND_MAIL_MONEY_CHANGED",
  "UPDATE_PENDING_MAIL",
  "NEW_WMO_CHUNK",
  "ZONE_CHANGED",
  "ZONE_CHANGED_INDOORS",
  "ZONE_CHANGED_NEW_AREA",
  "MAP_EXPLORATION_UPDATED",
  "MERCHANT_CLOSED",
  "MERCHANT_FILTER_ITEM_UPDATE",
  "MERCHANT_SHOW",
  "MERCHANT_UPDATE",
  "MINIMAP_PING",
  "MINIMAP_UPDATE_TRACKING",
  "MINIMAP_UPDATE_ZOOM",
  "UI_MODEL_SCENE_INFO_UPDATED",
  "FORBIDDEN_NAME_PLATE_CREATED",
  "FORBIDDEN_NAME_PLATE_UNIT_ADDED",
  "FORBIDDEN_NAME_PLATE_UNIT_REMOVED",
  "NAME_PLATE_CREATED",
  "NAME_PLATE_UNIT_ADDED",
  "NAME_PLATE_UNIT_REMOVED",
  "CHARACTER_POINTS_CHANGED",
  "COMBAT_RATING_UPDATE",
  "DISABLE_XP_GAIN",
  "ENABLE_XP_GAIN",
  "EQUIP_BIND_CONFIRM",
  "INSPECT_HONOR_UPDATE",
  "INSPECT_READY",
  "PET_SPELL_POWER_UPDATE",
  "PLAYER_AVG_ITEM_LEVEL_UPDATE",
  "PLAYER_EQUIPMENT_CHANGED",
  "SPELL_POWER_CHANGED",
  "UPDATE_FACTION",
  "UPDATE_INVENTORY_ALERTS",
  "UPDATE_INVENTORY_DURABILITY",
  "ENTERED_DIFFERENT_INSTANCE_FROM_PARTY",
  "GROUP_FORMED",
  "GROUP_INVITE_CONFIRMATION",
  "GROUP_JOINED",
  "GROUP_LEFT",
  "GROUP_ROSTER_UPDATE",
  "INSTANCE_BOOT_START",
  "INSTANCE_BOOT_STOP",
  "INSTANCE_GROUP_SIZE_CHANGED",
  "PARTY_INVITE_CANCEL",
  "PARTY_INVITE_REQUEST",
  "PARTY_LEADER_CHANGED",
  "PARTY_LOOT_METHOD_CHANGED",
  "PARTY_MEMBER_DISABLE",
  "PARTY_MEMBER_ENABLE",
  "PLAYER_ROLES_ASSIGNED",
  "RAID_ROSTER_UPDATE",
  "READY_CHECK",
  "READY_CHECK_CONFIRM",
  "READY_CHECK_FINISHED",
  "ROLE_CHANGED_INFORM",
  "PET_ATTACK_START",
  "PET_ATTACK_STOP",
  "PET_BAR_HIDEGRID",
  "PET_BAR_SHOWGRID",
  "PET_BAR_UPDATE_COOLDOWN",
  "PET_DISMISS_START",
  "PET_FORCE_NAME_DECLENSION",
  "PET_UI_CLOSE",
  "BATTLEFIELD_QUEUE_TIMEOUT",
  "BATTLEFIELDS_CLOSED",
  "BATTLEFIELDS_SHOW",
  "BATTLEGROUND_OBJECTIVES_UPDATE",
  "BATTLEGROUND_POINTS_UPDATE",
  "GDF_SIM_COMPLETE",
  "NOTIFY_PVP_AFK_RESULT",
  "PLAYER_ENTERING_BATTLEGROUND",
  "PVP_WORLDSTATE_UPDATE",
  "UPDATE_ACTIVE_BATTLEFIELD",
  "UPDATE_BATTLEFIELD_SCORE",
  "UPDATE_BATTLEFIELD_STATUS",
  "WARGAME_REQUESTED",
  "QUEST_ACCEPTED",
  "QUEST_AUTOCOMPLETE",
  "QUEST_COMPLETE",
  "QUEST_DETAIL",
  "QUEST_LOG_UPDATE",
  "QUEST_REMOVED",
  "QUEST_TURNED_IN",
  "QUEST_WATCH_LIST_CHANGED",
  "QUEST_WATCH_UPDATE",
  "SUPER_TRACKED_QUEST_CHANGED",
  "TASK_PROGRESS_UPDATE",
  "QUEST_ACCEPT_CONFIRM",
  "QUEST_FINISHED",
  "QUEST_GREETING",
  "QUEST_ITEM_UPDATE",
  "QUEST_PROGRESS",
  "LEVEL_GRANT_PROPOSED",
  "PARTY_REFER_A_FRIEND_UPDATED",
  "RECRUIT_A_FRIEND_CAN_EMAIL",
  "RECRUIT_A_FRIEND_INVITATION_FAILED",
  "RECRUIT_A_FRIEND_INVITER_FRIEND_ADDED",
  "RECRUIT_A_FRIEND_SYSTEM_STATUS",
  "SOR_BY_TEXT_UPDATED",
  "SOR_COUNTS_UPDATED",
  "SOR_START_EXPERIENCE_INCOMPLETE",
  "ADDON_ACTION_BLOCKED",
  "ADDON_ACTION_FORBIDDEN",
  "MACRO_ACTION_BLOCKED",
  "MACRO_ACTION_FORBIDDEN",
  "LUA_WARNING",
  "SECURE_TRANSFER_CANCEL",
  "SECURE_TRANSFER_CONFIRM_SEND_MAIL",
  "SECURE_TRANSFER_CONFIRM_TRADE_ACCEPT",
  "SKILL_LINES_CHANGED",
  "SOCIAL_ITEM_RECEIVED",
  "TWITTER_LINK_RESULT",
  "TWITTER_POST_RESULT",
  "TWITTER_STATUS_UPDATE",
  "SOUND_DEVICE_UPDATE",
  "SOUNDKIT_FINISHED",
  "CONFIRM_PET_UNLEARN",
  "CONFIRM_TALENT_WIPE",
  "SPELL_DATA_LOAD_RESULT",
  "CURRENT_SPELL_CAST_CHANGED",
  "LEARNED_SPELL_IN_TAB",
  "MAX_SPELL_START_RECOVERY_OFFSET_CHANGED",
  "PLAYER_TOTEM_UPDATE",
  "SPELL_TEXT_UPDATE",
  "SPELL_UPDATE_CHARGES",
  "SPELL_UPDATE_COOLDOWN",
  "SPELL_UPDATE_ICON",
  "SPELL_UPDATE_USABLE",
  "SPELLS_CHANGED",
  "START_AUTOREPEAT_SPELL",
  "STOP_AUTOREPEAT_SPELL",
  "UNIT_SPELLCAST_SENT",
  "UPDATE_SHAPESHIFT_COOLDOWN",
  "UPDATE_SHAPESHIFT_FORM",
  "UPDATE_SHAPESHIFT_FORMS",
  "UPDATE_SHAPESHIFT_USABLE",
  "PET_STABLE_CLOSED",
  "PET_STABLE_SHOW",
  "PET_STABLE_UPDATE",
  "PET_STABLE_UPDATE_PAPERDOLL",
  "CAPTUREFRAMES_FAILED",
  "CAPTUREFRAMES_SUCCEEDED",
  "DISABLE_TAXI_BENCHMARK",
  "ENABLE_TAXI_BENCHMARK",
  "GENERIC_ERROR",
  "INITIAL_HOTFIXES_APPLIED",
  "LOC_RESULT",
  "LOGOUT_CANCEL",
  "PLAYER_CAMPING",
  "PLAYER_ENTERING_WORLD",
  "PLAYER_LEAVING_WORLD",
  "PLAYER_LOGIN",
  "PLAYER_LOGOUT",
  "PLAYER_QUITING",
  "SEARCH_DB_LOADED",
  "STREAMING_ICON",
  "SYSMSG",
  "TIME_PLAYED_MSG",
  "UI_ERROR_MESSAGE",
  "UI_INFO_MESSAGE",
  "VARIABLES_LOADED",
  "WOW_MOUSE_NOT_FOUND",
  "TAXIMAP_CLOSED",
  "TAXIMAP_OPENED",
  "PLAYER_TRADE_MONEY",
  "TRADE_ACCEPT_UPDATE",
  "TRADE_CLOSED",
  "TRADE_MONEY_CHANGED",
  "TRADE_PLAYER_ITEM_CHANGED",
  "TRADE_POTENTIAL_BIND_ENCHANT",
  "TRADE_REQUEST",
  "TRADE_REQUEST_CANCEL",
  "TRADE_SHOW",
  "TRADE_TARGET_ITEM_CHANGED",
  "TRADE_UPDATE",
  "NEW_RECIPE_LEARNED",
  "TRADE_SKILL_CLOSE",
  "TRADE_SKILL_DATA_SOURCE_CHANGED",
  "TRADE_SKILL_DATA_SOURCE_CHANGING",
  "TRADE_SKILL_DETAILS_UPDATE",
  "TRADE_SKILL_LIST_UPDATE",
  "TRADE_SKILL_NAME_UPDATE",
  "TRADE_SKILL_SHOW",
  "TRADE_SKILL_UPDATE",
  "UPDATE_TRADESKILL_RECAST",
  "TRAINER_CLOSED",
  "TRAINER_DESCRIPTION_UPDATE",
  "TRAINER_SERVICE_INFO_NAME_UPDATE",
  "TRAINER_SHOW",
  "TRAINER_UPDATE",
  "TUTORIAL_TRIGGER",
  "UI_SCALE_CHANGED",
  "UPDATE_ALL_UI_WIDGETS",
  "UPDATE_UI_WIDGET",
  "DISPLAY_SIZE_CHANGED",
  "GLUE_SCREENSHOT_FAILED",
  "SCREENSHOT_FAILED",
  "SCREENSHOT_STARTED",
  "SCREENSHOT_SUCCEEDED",
  "VOICE_CHAT_ACTIVE_INPUT_DEVICE_UPDATED",
  "VOICE_CHAT_ACTIVE_OUTPUT_DEVICE_UPDATED",
  "VOICE_CHAT_AUDIO_CAPTURE_ENERGY",
  "VOICE_CHAT_AUDIO_CAPTURE_STARTED",
  "VOICE_CHAT_AUDIO_CAPTURE_STOPPED",
  "VOICE_CHAT_CHANNEL_ACTIVATED",
  "VOICE_CHAT_CHANNEL_DEACTIVATED",
  "VOICE_CHAT_CHANNEL_DISPLAY_NAME_CHANGED",
  "VOICE_CHAT_CHANNEL_JOINED",
  "VOICE_CHAT_CHANNEL_MEMBER_ACTIVE_STATE_CHANGED",
  "VOICE_CHAT_CHANNEL_MEMBER_ADDED",
  "VOICE_CHAT_CHANNEL_MEMBER_ENERGY_CHANGED",
  "VOICE_CHAT_CHANNEL_MEMBER_GUID_UPDATED",
  "VOICE_CHAT_CHANNEL_MEMBER_MUTE_FOR_ALL_CHANGED",
  "VOICE_CHAT_CHANNEL_MEMBER_MUTE_FOR_ME_CHANGED",
  "VOICE_CHAT_CHANNEL_MEMBER_REMOVED",
  "VOICE_CHAT_CHANNEL_MEMBER_SILENCED_CHANGED",
  "VOICE_CHAT_CHANNEL_MEMBER_SPEAKING_STATE_CHANGED",
  "VOICE_CHAT_CHANNEL_MEMBER_VOLUME_CHANGED",
  "VOICE_CHAT_CHANNEL_MUTE_STATE_CHANGED",
  "VOICE_CHAT_CHANNEL_PTT_CHANGED",
  "VOICE_CHAT_CHANNEL_REMOVED",
  "VOICE_CHAT_CHANNEL_TRANSMIT_CHANGED",
  "VOICE_CHAT_CHANNEL_VOLUME_CHANGED",
  "VOICE_CHAT_COMMUNICATION_MODE_CHANGED",
  "VOICE_CHAT_CONNECTION_SUCCESS",
  "VOICE_CHAT_DEAFENED_CHANGED",
  "VOICE_CHAT_ERROR",
  "VOICE_CHAT_INPUT_DEVICES_UPDATED",
  "VOICE_CHAT_LOGIN",
  "VOICE_CHAT_LOGOUT",
  "VOICE_CHAT_MUTED_CHANGED",
  "VOICE_CHAT_OUTPUT_DEVICES_UPDATED",
  "VOICE_CHAT_PENDING_CHANNEL_JOIN_STATE",
  "VOICE_CHAT_PTT_BUTTON_PRESSED_STATE_CHANGED",
  "VOICE_CHAT_SILENCED_CHANGED",
  "START_TIMER",
  "WORLD_STATE_TIMER_START",
  "WORLD_STATE_TIMER_STOP",
  "TOKEN_AUCTION_SOLD",
  "TOKEN_BUY_CONFIRM_REQUIRED",
  "TOKEN_BUY_RESULT",
  "TOKEN_CAN_VETERAN_BUY_UPDATE",
  "TOKEN_DISTRIBUTIONS_UPDATED",
  "TOKEN_MARKET_PRICE_UPDATED",
  "TOKEN_REDEEM_BALANCE_UPDATED",
  "TOKEN_REDEEM_CONFIRM_REQUIRED",
  "TOKEN_REDEEM_FRAME_SHOW",
  "TOKEN_REDEEM_GAME_TIME_UPDATED",
  "TOKEN_REDEEM_RESULT",
  "TOKEN_SELL_CONFIRM_REQUIRED",
  "TOKEN_SELL_RESULT",
  "TOKEN_STATUS_CHANGED",
  "MAX_EXPANSION_LEVEL_UPDATED",
  "MIN_EXPANSION_LEVEL_UPDATED",
  "AUTOFOLLOW_BEGIN",
  "AUTOFOLLOW_END",
  "CANCEL_SUMMON",
  "CONFIRM_BINDER",
  "CONFIRM_SUMMON",
  "HEARTHSTONE_BOUND",
  "INCOMING_RESURRECT_CHANGED",
  "LOCALPLAYER_PET_RENAMED",
  "MIRROR_TIMER_PAUSE",
  "MIRROR_TIMER_START",
  "MIRROR_TIMER_STOP",
  "OBJECT_ENTERED_AOI",
  "OBJECT_LEFT_AOI",
  "PET_BAR_UPDATE_USABLE",
  "PET_UI_UPDATE",
  "PLAYER_DAMAGE_DONE_MODS",
  "PLAYER_ENTER_COMBAT",
  "PLAYER_FARSIGHT_FOCUS_CHANGED",
  "PLAYER_FLAGS_CHANGED",
  "PLAYER_LEAVE_COMBAT",
  "PLAYER_LEVEL_CHANGED",
  "PLAYER_LEVEL_UP",
  "PLAYER_MOUNT_DISPLAY_CHANGED",
  "PLAYER_PVP_KILLS_CHANGED",
  "PLAYER_PVP_RANK_CHANGED",
  "PLAYER_REGEN_DISABLED",
  "PLAYER_REGEN_ENABLED",
  "PLAYER_STARTED_MOVING",
  "PLAYER_STOPPED_MOVING",
  "PLAYER_TARGET_CHANGED",
  "PLAYER_TARGET_SET_ATTACKING",
  "PLAYER_TRIAL_XP_UPDATE",
  "PLAYER_UPDATE_RESTING",
  "PLAYER_XP_UPDATE",
  "PORTRAITS_UPDATED",
  "PVP_TIMER_UPDATE",
  "SPELL_CONFIRMATION_PROMPT",
  "SPELL_CONFIRMATION_TIMEOUT",
  "UNIT_ATTACK",
  "UNIT_ATTACK_POWER",
  "UNIT_ATTACK_SPEED",
  "UNIT_AURA",
  "UNIT_CHEAT_TOGGLE_EVENT",
  "UNIT_CLASSIFICATION_CHANGED",
  "UNIT_COMBAT",
  "UNIT_CONNECTION",
  "UNIT_DAMAGE",
  "UNIT_DEFENSE",
  "UNIT_DISPLAYPOWER",
  "UNIT_FACTION",
  "UNIT_FLAGS",
  "UNIT_HAPPINESS",
  "UNIT_HEALTH",
  "UNIT_HEALTH_FREQUENT",
  "UNIT_INVENTORY_CHANGED",
  "UNIT_LEVEL",
  "UNIT_MANA",
  "UNIT_MAXHEALTH",
  "UNIT_MAXPOWER",
  "UNIT_MODEL_CHANGED",
  "UNIT_NAME_UPDATE",
  "UNIT_OTHER_PARTY_CHANGED",
  "UNIT_PET",
  "UNIT_PET_EXPERIENCE",
  "UNIT_PET_TRAINING_POINTS",
  "UNIT_PHASE",
  "UNIT_PORTRAIT_UPDATE",
  "UNIT_POWER_BAR_HIDE",
  "UNIT_POWER_BAR_SHOW",
  "UNIT_POWER_BAR_TIMER_UPDATE",
  "UNIT_POWER_FREQUENT",
  "UNIT_POWER_UPDATE",
  "UNIT_QUEST_LOG_CHANGED",
  "UNIT_RANGED_ATTACK_POWER",
  "UNIT_RANGEDDAMAGE",
  "UNIT_RESISTANCES",
  "UNIT_SPELL_HASTE",
  "UNIT_SPELLCAST_CHANNEL_START",
  "UNIT_SPELLCAST_CHANNEL_STOP",
  "UNIT_SPELLCAST_CHANNEL_UPDATE",
  "UNIT_SPELLCAST_DELAYED",
  "UNIT_SPELLCAST_FAILED",
  "UNIT_SPELLCAST_FAILED_QUIET",
  "UNIT_SPELLCAST_INTERRUPTED",
  "UNIT_SPELLCAST_START",
  "UNIT_SPELLCAST_STOP",
  "UNIT_SPELLCAST_SUCCEEDED",
  "UNIT_STATS",
  "UNIT_TARGET",
  "UNIT_TARGETABLE_CHANGED",
  "UNIT_THREAT_LIST_UPDATE",
  "UNIT_THREAT_SITUATION_UPDATE",
  "UPDATE_EXHAUSTION",
  "UPDATE_MOUSEOVER_UNIT",
  "UPDATE_STEALTH",
}