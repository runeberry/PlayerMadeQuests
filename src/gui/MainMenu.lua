local _, addon = ...
local UISpecialFrames = addon.G.UISpecialFrames

local firstShow = true
local defaultMenu = "AboutMenu"

local function initMainMenu()
  addon.MainMenu = addon.CustomWidgets:CreateWidget("TreeMenuFrame")
  addon.MainMenu:SetTitle("PlayerMadeQuests")
  addon.MainMenu:SetStatusText("PMQ "..addon:GetVersionText().." (thank you for testing! <3)")
  addon.MainMenu:SetMenuTree({ -- value == menuId
    { value = "AboutMenu", text = "About PMQ" },
    { value = "QuestMenu-Placeholder", text = "Quests",
      children = {
        { value = "QuestCatalogMenu", text = "Quest Catalog" },
        { value = "QuestDemoListMenu", text = "Demo Quests" },
        { value = "QuestDraftListMenu", text = "My Drafts" },
        { value = "QuestLogMenu", text = "My Quest Log" },
        { value = "QuestRewardsMenu", text = "Quest Rewards" },
        { value = "QuestArchiveMenu", text = "Quest Archive" },
      }
    },
    { value = "SettingsMenu-Placeholder", text = "Settings",
      children = {
        { value = "ConfigMenu", text = "Configuration" },
        { value = "LoggingMenu", text = "Logging" },
        { value = "SaveDataMenu", text = "Save Data & Cache" },
      }
    },
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
  local mmfGlobalName = addon:CreateGlobalName("MainMenuFrame")
  _G[mmfGlobalName] = addon.MainMenu
  table.insert(UISpecialFrames, mmfGlobalName)
end

-- todo: move this to lifecycle, if I can figure out the timing...
addon:catch(function()
  initMainMenu()
end)

addon:OnGuiReady(function()
  addon.MainMenu:SetVisibleTreeDepth(2)
  local startMenu = addon.Config:GetValue("START_MENU")
  if startMenu and startMenu ~= "" then
    defaultMenu = startMenu
    -- For some reason, the menu won't show on this frame, so let's delay it
    addon.Ace:ScheduleTimer(function()
      addon.MainMenu:Show()
    end, 0.5)
  end
end)