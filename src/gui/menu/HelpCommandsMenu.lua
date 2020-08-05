local _, addon = ...

local menu = addon.MainMenu:NewMenuScreen("HelpCommandsMenu")

local textinfo = {
  static = true,
  styles = addon.DefaultArticleTextStyle,
  text = {
    {
      style = "default",
      text = "You can open the main menu by using the command "..addon:Colorize("orange", "/pmq").." anytime. Here are some other commands you can use:"
    },
    {
      style = "highlight",
      text = "/pmq show",
    },
    {
      style = "default",
      text = "Shows your PMQ quest log.",
    },
    {
      style = "highlight",
      text = "/pmq hide",
    },
    {
      style = "default",
      text = "Hides your PMQ quest log.",
    },
    {
      style = "highlight",
      text = "/pmq reset"
    },
    {
      style = "default",
      text = "Resets your PMQ quest log and archive. Deletes all quests without confirmation!",
    },
  }
}

function menu:Create(frame)
  local article = addon.CustomWidgets:CreateWidget("ArticleText", frame, textinfo)
  article:SetAllPoints(true)
end
