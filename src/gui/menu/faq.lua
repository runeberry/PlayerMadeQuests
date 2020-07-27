local _, addon = ...

local menu = addon.MainMenu:NewMenuScreen("faq")

local textinfo = {
  static = true,
  styles = {
    ["header"] = {
      inheritsFrom = "GameFontNormalLarge",
      justifyH = "LEFT"
    },
    ["default"] = {
      inheritsFrom = "GameFontHighlightSmall",
      justifyH = "LEFT",
      spacing = 2
    }
  },
  text = {
    {
      style = "header",
      text = "What is this addon for?",
    },
    {
      style = "default",
      text = "PlayerMadeQuests (PMQ) is a platform for creating your own WoW-style quests and sharing them with other players. It feature real live objective tracking, so it feels just like doing a real WoW quest!",
    },
    {
      style = "header",
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
}

function menu:Create(frame)
  addon.CustomWidgets:CreateWidget("ArticleText", frame, textinfo)
end
