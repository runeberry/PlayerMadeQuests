local _, addon = ...
addon:traceFile("MessageEvents.lua")
local Ace, unpack = addon.Ace, addon.G.unpack
local encoder = addon.LibCompress:GetAddonEncodeTable()

local PMQ_MESSAGE_PREFIX = "PMQ"
local defaultDetails = {
  distribution = "PARTY", -- see: https://wow.gamepedia.com/API_C_ChatInfo.SendAddonMessage
  target = nil, -- player name, required only for "WHISPER"
  priority = "NORMAL" -- also allowed: "BULK", "ALERT"
}
local internalPublish

addon.MessageEvents = addon.Events:CreateBroker("MessageEvent")
addon.MessageEvents:SetLogLevel(addon.LogLevel.trace)
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
  local decoded = encoder:Decode(message)
  local payload = addon:DecompressTable(decoded)
  internalPublish(payload.e, distribution, sender, unpack(payload.p))
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
  Ace:SendCommMessage(PMQ_MESSAGE_PREFIX, encoded, details.distribution, details.target, details.priority)
end

function addon.MessageEvents:Start()
  if self.started then return end

  -- The original publish method will be used when an incoming message is received
  internalPublish = addon.MessageEvents.Publish
  addon.MessageEvents.Publish = broker_publishMessage

  Ace:RegisterComm(PMQ_MESSAGE_PREFIX, onCommReceived)

  self.started = true
end

addon:onload(function()
  addon.MessageEvents:Start()
end)