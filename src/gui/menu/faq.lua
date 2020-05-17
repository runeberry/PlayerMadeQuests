local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local menu = addon.MainMenu:NewMenuScreen([[help\faq]], "FAQs", true)
local _frame

local faq = {
  {
    q = "What is this addon for?",
    a = [[PlayerMadeQuests (PMQ) is a platform for creating your own WoW-style quests and sharing them with other players. It feature real live objective tracking, so it feels just like doing a real WoW quest!]]
  },
  {
    q = "Why didn't my data get saved?",
    a = [[You must encounter a loading screen or safely exit the game in order for your quest progress to be saved to disk. This is a limitation of all WoW addons. You can /reload to manually save your data anytime.

If you get disconnected from the server, your save data will not be updated. Make sure to save often if you're having connection issues!]]
  },
}

function menu:Create(parent)
  -- local frame = CreateFrame("SimpleHTML", nil, parent)
  -- -- frame:SetFontObject("GameFontHighlightSmall")
  -- frame:SetFont("p", "GameFontHightlightSmall", 11)
  -- frame:SetFont("h2", "GameFontNormalLarge", 16)
  -- frame:SetText(content)

  -- frame:SetAllPoints(true)

  local frame = CreateFrame("Frame", nil, parent)
  frame:SetAllPoints(true)

  local anchorFrame
  for _, item in pairs(faq) do
    local question = frame:CreateFontString(nil, "BACKGROUND")
    question:SetFontObject("GameFontNormalLarge")
    question:SetJustifyH("LEFT")
    question:SetText(item.q)

    if not anchorFrame then
      question:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -6)
      question:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
    else
      question:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -6)
      question:SetPoint("TOPRIGHT", anchorFrame, "BOTTOMRIGHT")
    end

    local answer = frame:CreateFontString(nil, "BACKGROUND")
    answer:SetFontObject("GameFontHighlightSmall")
    answer:SetJustifyH("LEFT")
    answer:SetSpacing(2)
    answer:SetText(item.a)
    answer:SetPoint("TOPLEFT", question, "BOTTOMLEFT", 0, -6)
    answer:SetPoint("TOPRIGHT", question, "BOTTOMRIGHT")

    anchorFrame = answer
  end

  return frame
end
