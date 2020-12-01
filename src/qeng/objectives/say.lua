local _, addon = ...
local tokens = addon.QuestScriptTokens

local objective = addon.QuestEngine:NewObjective("say")

objective:AddShorthandForm(tokens.PARAM_MESSAGE)

objective:AddParameter(tokens.PARAM_TEXT, {
  defaultValue = {
    log = "Say \"%msg\"",
    progress = "Say \"%msg\"[%lang: in %lang][%ch: in %ch][%t: to %t]",
    quest = "Say \"%msg\"[%lang: in %lang][%ch: in %ch][%t: to %t][%xyz: in %xyz][%a: while having %a][%i: while having %i][%e: while wearing %e]",
    full = "Say \"%msg\"[%lang: in %lang][%ch: in %ch][%t: to %t][%xyz: in %xyrz][%a: while having %a][%i: while having %i][%e: while wearing %e]"
  },
})

-- Chat message specific conditions
objective:AddCondition(tokens.PARAM_MESSAGE, { required = true })
objective:AddCondition(tokens.PARAM_LANGUAGE)
objective:AddCondition(tokens.PARAM_CHANNEL)
objective:AddCondition(tokens.PARAM_MESSAGETARGET, { alias = tokens.PARAM_TARGET })

objective:AddCondition(tokens.PARAM_AURA)
objective:AddCondition(tokens.PARAM_EQUIP)
objective:AddCondition(tokens.PARAM_ITEM)
objective:AddCondition(tokens.PARAM_ZONE)
objective:AddCondition(tokens.PARAM_SUBZONE)
objective:AddCondition(tokens.PARAM_COORDS)

local function handleChatMsg(channel, message, _, language, _, player)
  -- Only consider chat messages sent by the player
  if (channel == "whisper") then
    -- CHAT_MSG_WHISPER_INFORM is fired on send, CHAT_MSG_WHISPER is fired on receipt
    -- So if we hear this channel from the event below, then we know the player sent it
    addon.LastChatChannel = channel
    addon.LastChatMessage = message
    addon.LastChatLanguage = nil -- Whispers cannot be sent in RP language
    addon.LastChatRecipient = player -- For this event, this arg is the player the msg was sent to
    return true
  elseif (player == addon:GetPlayerName()) then -- Otherwise, this arg is the message sender
    addon.LastChatChannel = channel
    addon.LastChatMessage = message
    addon.LastChatLanguage = language
    addon.LastChatRecipient = nil -- Only applicable to whispers
    return true
  end
end

objective:AddGameEvent("CHAT_MSG_SAY", function(...) return handleChatMsg("say", ...) end)
objective:AddGameEvent("CHAT_MSG_YELL", function(...) return handleChatMsg("yell", ...) end)
objective:AddGameEvent("CHAT_MSG_PARTY", function(...) return handleChatMsg("party", ...) end)
objective:AddGameEvent("CHAT_MSG_RAID", function(...) return handleChatMsg("raid", ...) end)
objective:AddGameEvent("CHAT_MSG_GUILD", function(...) return handleChatMsg("guild", ...) end)
objective:AddGameEvent("CHAT_MSG_WHISPER_INFORM", function(...) return handleChatMsg("whisper", ...) end)