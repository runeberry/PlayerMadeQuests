local _, addon = ...
local Config, ConfigSource = addon.Config
local CreateFrame = addon.G.CreateFrame

local menu = addon.MainMenu:NewMenuScreen("AboutMenu")

function menu:Create(frame)
  local logo = addon:CreateImageFrame("Logo", frame)
  logo:SetPoint("TOPRIGHT", frame, "TOPRIGHT")

  local headerTextInfo = {
    static = true,
    styles = addon.DefaultArticleTextStyle,
    text = {
      {
        style = "page-header",
        text = string.format("PlayerMadeQuests (%s)", addon:GetVersionText()),
      },
      {
        style = "default-centered",
        text = "(c) 2020 Runeberry Software, LLC\nLicensed under GNU GPL v3.0",
      },
    }
  }

  local headerArticle = addon.CustomWidgets:CreateWidget("ArticleText", frame, headerTextInfo)
  headerArticle:ClearAllPoints(true)
  headerArticle:SetPoint("TOPLEFT", frame, "TOPLEFT")
  headerArticle:SetPoint("BOTTOMRIGHT", logo, "BOTTOMLEFT")

  local bodyTextInfo = {
    static = true,
    styles = addon.DefaultArticleTextStyle,
    text = {
      {
        style = "header",
        text = "Getting Started",
      },
      {
        style = "default",
        text = "PMQ allows you to write, play, and share your own custom quests. With a few lines of script, you can create an adventure that plays just like a real World of Warcraft quest, complete with tracked objectives, custom dialogue, and more!"
      },
      {
        style = "default",
        text = "Ready to get started?"
      },
      {
        style = "default",
        text = "    > Try out the "..addon:Colorize("orange", "Demo Quests").." bundled with PMQ to learn how to write your own.\n"..
               "    > Start customizing any Demo Quest with "..addon:Colorize("orange", "Copy to Drafts").." from the View Code page.\n"..
               "    > Write quests from scratch and share them with your party from the "..addon:Colorize("orange", "My Drafts").." page.\n"..
               "    > Checkout the "..addon:Colorize("orange", "PMQ Wiki").." (link below) for even more ways to customize your quests.",
      },
      {
        style = "header",
        text = "\nCommunity Resources", -- Extra newline for spacing
      },
      {
        style = "highlight",
        text = "PMQ Wiki - "..addon:Colorize("blue", addon.Config:GetValue("URL_WIKI"))
      },
      {
        style = "default",
        text = "    Learn everything you need to know about writing and sharing quests",
      },
      {
        style = "highlight",
        text = "Discord - "..addon:Colorize("blue", addon.Config:GetValue("URL_DISCORD")),
      },
      {
        style = "default",
        text = "    Make suggestions, report bugs, and keep up with new releases",
      },
      {
        style = "highlight",
        text = "Github - "..addon:Colorize("blue", addon.Config:GetValue("URL_GITHUB")),
      },
      {
        style = "default",
        text = "    Contribute code to PMQ, or check out what Issues we're working on next",
      }
    }
  }

  local bodyArticle = addon.CustomWidgets:CreateWidget("ArticleText", frame, bodyTextInfo)
  bodyArticle:ClearAllPoints(true)
  bodyArticle:SetPoint("TOPLEFT", headerArticle, "BOTTOMLEFT")
  bodyArticle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
end