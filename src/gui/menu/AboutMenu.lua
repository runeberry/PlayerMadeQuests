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
        text = "Developed & Produced By: Runeberry Software LLC",
      }
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
        text = "Community Resources",
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