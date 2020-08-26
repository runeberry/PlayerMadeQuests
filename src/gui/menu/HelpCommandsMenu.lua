local _, addon = ...

local menu = addon.MainMenu:NewMenuScreen("HelpCommandsMenu")

function menu:Create(frame)
  local textinfo = {
    static = true,
    styles = addon.DefaultArticleTextStyle,
    text = {
      {
        style = "default",
        text = "You can open the main menu by using the command "..addon:Colorize("orange", "/pmq").." anytime. Here are some other commands you can use:"
      }
    }
  }

  local commandsList = {
    {
      command = "/pmq emote",
      description = "Toggle the Emote Menu frame."
    },
    {
      command = "/pmq log",
      description = "Toggle the Quest Log frame."
    },
    {
      command = "/pmq location",
      description = "Toggle the Location Finder frame."
    },
    {
      command = "/pmq reset-config",
      description = "Prompts you to reset all config values for the addon."
    },
    {
      command = "/talk",
      description = "You can use this emote on a target to complete any talk-to objective, including targets that you're unable to talk to otherwise. However, you must be within 10y of the target for it to count."
    }
  }

  for _, c in ipairs(commandsList) do
    textinfo.text[#textinfo.text+1] = { style = "highlight", text = c.command }
    textinfo.text[#textinfo.text+1] = { style = "default", text = c.description }
  end

  local article = addon.CustomWidgets:CreateWidget("ArticleText", frame, textinfo)
  article:SetAllPoints(true)
end