local _, addon = ...
local CreateFrame = addon.G.CreateFrame

local menu = addon.MainMenu:NewMenuScreen("QuestBuilderMenu")

local dtOptions = {
  colInfo = {
    {
      name = "Objectives",
      align = "LEFT",
    }
  },
  dataSource = function()
    return {
      { "Explore the hidden cave" },
      { "Equip a Fine Scimitar" },
      { "Kill 3 Cobalt Wyrm" },
    }
  end,
  buttons = {
    {
      text = "Add",
      anchor = "TOP",
      enabled = "Always",
    },
    {
      text = "Edit",
      anchor = "TOP",
      enabled = "Row",
    },
    {
      text = "Remove",
      anchor = "TOP",
      enabled = "Row",
    },
  }
}

local function createFontLabelPair(parent, textLeft, textRight)
  local label = parent:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall")
  label:SetText(textLeft)
  label:SetWidth(96)
  label:SetJustifyH("RIGHT")

  local data = parent:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
  data:SetText(textRight)
  data:SetWidth(194)
  data:SetJustifyH("LEFT")
  data:SetPoint("LEFT", label, "RIGHT", 4, 0)

  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetText("Edit")
  button:SetSize(40, 16)
  button:SetPoint("LEFT", data, "RIGHT")

  local help = parent:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall")
  help:SetText("(?)")
  help:SetPoint("LEFT", button, "RIGHT", 4, 0)

  return label, data
end

function menu:Create(frame)
  local textinfo = {
    static = true,
    styles = addon.DefaultArticleTextStyle,
    text = {
      {
        style = "page-header",
        text = "Editing Draft: GuildQuest_WS1",
      }
    }
  }

  local article = addon.CustomWidgets:CreateWidget("ArticleText", frame, textinfo)
  article:ClearAllPoints(true)
  article:SetPoint("TOPLEFT", frame, "TOPLEFT")
  article:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
  article:SetHeight(24)

  local optsFrame = CreateFrame("Frame", nil, frame)
  optsFrame:SetPoint("TOPLEFT", article, "BOTTOMLEFT")
  optsFrame:SetSize(400, 208)

  local label1, data1 = createFontLabelPair(optsFrame, "Quest Name:", "Dragon Tails")
  label1:SetPoint("TOPLEFT", optsFrame, "TOPLEFT", 4, -4)

  local label2, data2 = createFontLabelPair(optsFrame, "Location:", "Winterspring")
  label2:SetPoint("TOPLEFT", label1, "BOTTOMLEFT", 0, -4)

  local label3, data3 = createFontLabelPair(optsFrame, "Start:", addon:Colorize("grey", "Anywhere"))
  label3:SetPoint("TOPLEFT", label2, "BOTTOMLEFT", 0, -4)

  local label4, data4 = createFontLabelPair(optsFrame, "Complete:", "Mezrik Fizzlespring, Everlook")
  label4:SetPoint("TOPLEFT", label3, "BOTTOMLEFT", 0, -4)

  local label5, data5 = createFontLabelPair(optsFrame, "Required:", addon:Colorize("grey", "None"))
  label5:SetPoint("TOPLEFT", label4, "BOTTOMLEFT", 0, -4)

  local label6, data6 = createFontLabelPair(optsFrame, "Recommended:", "Level 58+")
  label6:SetPoint("TOPLEFT", label5, "BOTTOMLEFT", 0, -4)

  local dtFrame = CreateFrame("Frame", nil, frame)
  dtFrame:SetSize(400, 100)
  dtFrame:SetPoint("BOTTOMLEFT", optsFrame, "BOTTOMLEFT")

  local dtwb = addon.CustomWidgets:CreateWidget("DataTableWithButtons", dtFrame, dtOptions)
  local dt = dtwb:GetDataTable()
  dt:RefreshData()

  local buttonPane = addon.CustomWidgets:CreateWidget("ButtonPane", frame, "BOTTOM")
  buttonPane:AddButton("Back to Drafts", function() end, { anchor = "LEFT" })
  buttonPane:AddButton("Preview Quest", function() end, { anchor = "LEFT" })
  buttonPane:AddButton("Play Quest", function() end, { anchor = "LEFT" })
end

function menu:OnShowMenu(frame)

end

function menu:OnLeaveMenu(frame)

end