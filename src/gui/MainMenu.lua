local _, addon = ...
addon:traceFile("MainMenu.lua")
local UISpecialFrames = addon.G.UISpecialFrames

addon.MainMenu = addon.CustomWidgets:CreateWidget("TreeMenuFrame")
addon.MainMenu:SetTitle("PlayerMadeQuests")
addon.MainMenu:SetStatusText("PMQ "..addon.ADDON_VERSION.." (thank you for testing! <3)")
addon.MainMenu:SetMenuTree({ -- value == menuId
  { value = "drafts", text = "My Questography" },
  { value = "demo", text = "Demo Quests" },
  { value = "settings", text = "Settings" },
  { value = "help", text = "Help",
    children = {
      { value = "about", text = "About PMQ" },
      { value = "faq", text = "FAQs" }
    }
  },
})

-- Make closable with ESC
local mmfGlobalName = "PMQ_MainMenuFrame"
_G[mmfGlobalName] = addon.MainMenu
table.insert(UISpecialFrames, mmfGlobalName)

addon:OnSaveDataLoaded(function()
  if addon.SHOW_MENU_ON_START then
    addon.MainMenu:NavToMenuScreen(addon.SHOW_MENU_ON_START)
  end
end)