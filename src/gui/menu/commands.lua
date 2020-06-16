local _, addon = ...

local menu = addon.MainMenu:NewMenuScreen("commands")

local textStyles = {
  ["Header"] = {
    inheritsFrom = "GameFontNormalSmall",
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
    style = "default",
    text = "You can open the main menu by using the command "..addon:Colorize("orange", "/pmq").." anytime. Here are some other commands you can use:"
  },
  {
    style = "Header",
    text = "/pmq show",
  },
  {
    style = "default",
    text = "Shows your PMQ quest log.",
  },
  {
    style = "Header",
    text = "/pmq hide",
  },
  {
    style = "default",
    text = "Hides your PMQ quest log.",
  },
  {
    style = "Header",
    text = "/pmq reset"
  },
  {
    style = "default",
    text = "Resets your PMQ quest log. Abandons all quests without confirmation!",
  },
}

function menu:Create(frame)
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
