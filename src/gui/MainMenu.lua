local _, addon = ...
addon:traceFile("MainMenu.lua")
local UISpecialFrames = addon.G.UISpecialFrames

local firstShow = true
local defaultMenu = "drafts"

addon.MainMenu = addon.CustomWidgets:CreateWidget("TreeMenuFrame")
addon.MainMenu:SetTitle("PlayerMadeQuests")
addon.MainMenu:SetStatusText("PMQ "..addon:GetVersionText().." (thank you for testing! <3)")
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

addon:OnSaveDataLoaded(function()
  addon.MainMenu:SetVisibleTreeDepth(2)
  if addon.PlayerSettings["start-menu"] then
    defaultMenu = addon.PlayerSettings["start-menu"]
    addon.MainMenu:Show()
  end
end)