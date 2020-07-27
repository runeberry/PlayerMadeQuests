local _, addon = ...

local menu = addon.MainMenu:NewMenuScreen("commands")

local textinfo = {
  static = true,
  styles = {
    ["header"] = {
      inheritsFrom = "GameFontNormalSmall",
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
      style = "default",
      text = "You can open the main menu by using the command "..addon:Colorize("orange", "/pmq").." anytime. Here are some other commands you can use:"
    },
    {
      style = "header",
      text = "/pmq show",
    },
    {
      style = "default",
      text = "Shows your PMQ quest log.",
    },
    {
      style = "header",
      text = "/pmq hide",
    },
    {
      style = "default",
      text = "Hides your PMQ quest log.",
    },
    {
      style = "header",
      text = "/pmq reset"
    },
    {
      style = "default",
      text = "Resets your PMQ quest log and archive. Deletes all quests without confirmation!",
    },
  }
}

function menu:Create(frame)
  addon.CustomWidgets:CreateWidget("ArticleText", frame, textinfo)
end
