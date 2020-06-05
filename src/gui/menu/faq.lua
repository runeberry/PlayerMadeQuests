local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local menu = addon.MainMenu:NewMenuScreen("faq")

local textStyles = {
  ["Header"] = {
    inheritsFrom = "GameFontNormalLarge",
    justifyH = "LEFT"
  },
  ["default"] = {
    inheritsFrom = "GameFontHighlightSmall",
    justifyH = "LEFT",
    spacing = 2
  }
}

local textLines = {
  {
    style = "Header",
    text = "What is this addon for?",
  },
  {
    style = "default",
    text = "PlayerMadeQuests (PMQ) is a platform for creating your own WoW-style quests and sharing them with other players. It feature real live objective tracking, so it feels just like doing a real WoW quest!",
  },
  {
    style = "Header",
    text = "Why didn't my data get saved?",
  },
  {
    style = "default",
    text = "You must encounter a loading screen or safely exit the game in order for your quest progress to be saved to disk. This is a limitation of all WoW addons. You can /reload to manually save your data anytime.",
  },
  {
    style = "default",
    text = "If you get disconnected from the server, your save data will not be updated. Make sure to save often if you're having connection issues!",
  },
}

function menu:Create(parent)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetAllPoints(true)

  local article = addon.CustomWidgets:CreateWidget("ArticleText", frame)

  for name, style in pairs(textStyles) do
    article:SetTextStyle(name, style)
  end

  for _, item in ipairs(textLines) do
    article:AddText(item.text, item.style)
  end

  frame.article = article
  article:Assemble()

  return frame
end
