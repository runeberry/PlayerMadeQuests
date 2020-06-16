local _, addon = ...
addon:traceFile("MainMenu.lua")
local UISpecialFrames = addon.G.UISpecialFrames

addon.MainMenu = addon.CustomWidgets:CreateWidget("TreeMenuFrame")
addon.MainMenu:SetTitle("PlayerMadeQuests")
addon.MainMenu:SetStatusText("PMQ "..addon.ADDON_VERSION.." (thank you for testing! <3)")
addon.MainMenu:SetMenuTree({ -- value == menuId
  { value = "quests", text = "Quests",
    children = {
      { value = "catalog", text = "Quest Catalog" },
      { value = "demo", text = "Demo Quests" },
      { value = "drafts", text = "My Drafts" },
      { value = "questlog", text = "My Quest Log" },
    }
  },
  { value = "settings", text = "Settings" },
  { value = "help", text = "Help",
    children = {
      { value = "commands", text = "Commands" },
      { value = "faq", text = "FAQs" }
    }
  },
})

-- Make closable with ESC
local mmfGlobalName = "PMQ_MainMenuFrame"
_G[mmfGlobalName] = addon.MainMenu
table.insert(UISpecialFrames, mmfGlobalName)

addon:OnSaveDataLoaded(function()
  addon.MainMenu:SetVisibleTreeDepth(2)
  if addon.SHOW_MENU_ON_START then
    addon.MainMenu:NavToMenuScreen(addon.SHOW_MENU_ON_START)
  end
end)