local _, addon = ...
local UISpecialFrames = addon.G.UISpecialFrames

local firstShow = true
local defaultMenu = "QuestDemoListMenu"

addon.MainMenu = addon.CustomWidgets:CreateWidget("TreeMenuFrame")
addon.MainMenu:SetTitle("PlayerMadeQuests")
addon.MainMenu:SetStatusText("PMQ "..addon:GetVersionText().." (thank you for testing! <3)")
addon.MainMenu:SetMenuTree({ -- value == menuId
  { value = "QuestMenu-Placeholder", text = "Quests",
    children = {
      { value = "QuestCatalogMenu", text = "Quest Catalog" },
      { value = "QuestDemoListMenu", text = "Demo Quests" },
      { value = "QuestDraftListMenu", text = "My Drafts" },
      { value = "QuestLogMenu", text = "My Quest Log" },
      { value = "QuestArchiveMenu", text = "Quest Archive" },
    }
  },
  { value = "SettingsMenu", text = "Settings" },
  { value = "HelpMenu-Placeholder", text = "Help",
    children = {
      { value = "HelpCommandsMenu", text = "Commands" },
      { value = "HelpFaqMenu", text = "FAQs" },
    }
  },
})
addon.MainMenu:SetScript("OnShow", function()
  if firstShow then
    addon.MainMenu:NavToMenuScreen(defaultMenu)
    firstShow = false
  end
end)

-- Make closable with ESC
local mmfGlobalName = "PMQ_MainMenuFrame"
_G[mmfGlobalName] = addon.MainMenu
table.insert(UISpecialFrames, mmfGlobalName)

addon:OnGuiReady(function()
  addon.MainMenu:SetVisibleTreeDepth(2)
  if addon.PlayerSettings["start-menu"] then
    defaultMenu = addon.PlayerSettings["start-menu"]
    addon.MainMenu:Show()
  end
end)