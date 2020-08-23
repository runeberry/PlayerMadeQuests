local _, addon = ...
local Ace, unpack = addon.Ace, addon.G.unpack
local GetUnitName = addon.G.GetUnitName
local encoder = addon.LibCompress:GetAddonEncodeTable()

local PMQ_MESSAGE_PREFIX = "PMQ"
local defaultDetails = {
  distribution = "PARTY", -- see: https://wow.gamepedia.com/API_C_ChatInfo.SendAddonMessage
  target = nil, -- player name, required only for "WHISPER"
  priority = "NORMAL" -- also allowed: "BULK", "ALERT"
}
local useInternalMessaging
local internalPublish
local playerName

addon.MessageEvents = addon.Events:CreateBroker("MessageEvent")
addon.MessageEvents:EnableAsync()

--[[
  Message payload format:
  {
    e: "EventName",
    p: { -- varargs from Publish
      [1] = {},
      [2] = "thing",
      [3] = 27.5
    }
  }
--]]

local function onCommReceived(prefix, message, distribution, sender)
  addon.Logger:Trace("Message received for %s from %s", distribution, sender)
  if sender == playerName then return end -- Don't handle messages that you also sent out
  local decoded = encoder:Decode(message)
  local payload = addon:DecompressTable(decoded)
  internalPublish(addon.MessageEvents, payload.e, distribution, sender, unpack(payload.p))
end

-- This broker overrides the standard publish function with an implementation of its own
-- Ace docs here: https://www.wowace.com/projects/ace3/pages/api/ace-comm-3-0
-- "details" can be either a string (distribution), or a table like:
-- { distribution = "", target = "", priority = "" }
local function broker_publishMessage(self, event, details, ...)
  details = details or defaultDetails
  local payload = { e = event, p = { ... } }
  local compressed = addon:CompressTable(payload)
  local encoded = encoder:Encode(compressed)
  if useInternalMessaging then
    -- For development and unit testing only
    onCommReceived(PMQ_MESSAGE_PREFIX, encoded, details.distribution, "*yourself*")
    return
  end
  Ace:SendCommMessage(PMQ_MESSAGE_PREFIX, encoded, details.distribution, details.target, details.priority)
end

addon:OnBackendStart(function()
  useInternalMessaging = addon.Config:GetConfigValue("ENABLE_SELF_MESSAGING")

  playerName = GetUnitName("player")

  -- The original publish method will be used when an incoming message is received
  internalPublish = addon.MessageEvents.Publish
  addon.MessageEvents.Publish = broker_publishMessage

  Ace:RegisterComm(PMQ_MESSAGE_PREFIX, onCommReceived)
end)