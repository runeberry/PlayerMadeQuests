local _, addon = ...
local Emotes = addon.Emotes

addon.EmoteFrame = nil -- Built at end of file

local emoteRows

local frameOptions = {
  styleOptions = {
    text = "Emotes"
  },
  resizable = false,
  position = {
    p1 = "RIGHT",
    p2 = "RIGHT",
    x = -100,
    y = 0,
    w = 300,
    h = 300,
    shown = false
  }
}

local options = {
  colInfo = {
    {
      name = "Emote",
      pwidth = 0.6,
      align = "LEFT"
    },
    {
      name = "Command",
      pwidth = 0.4,
      align = "RIGHT"
    },
  },
  dataSource = function()
    emoteRows = {}
    local emotes = Emotes:FindAll()
    table.sort(emotes, function(a, b) return a.token < b.token end)
    for _, emote in pairs(emotes) do
        emote.token = string.lower(emote.token)
        emote.token = emote.token:gsub("^%l", string.upper)
      local row = { emote.token, emote.command }
      table.insert(emoteRows, row)
    end
    return emoteRows
  end,
}

local function buildEmoteFrame()
  local frame = addon.CustomWidgets:CreateWidget("ToolWindowPopout", "EmoteFrame", frameOptions)
  local contentFrame = frame:GetContentFrame()
  local dt = addon.CustomWidgets:CreateWidget("DataTable", contentFrame, options.colInfo, options.dataSource)
  dt:ClearAllPoints()
  dt:SetPoint("TOPLEFT", contentFrame, "TOPLEFT")
  dt:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", 0, 9)
  dt:RefreshData()
  return frame
end

addon:OnGuiStart(function()
  addon.EmoteFrame = buildEmoteFrame()
end)