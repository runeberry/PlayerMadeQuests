local _, addon = ...
local CreateFrame = addon.G.CreateFrame
local QuestDemos = addon.QuestDemos

local menu = addon.MainMenu:NewMenuScreen([[demo-view]], "Demo Quest View")

-- Use this for display testing
-- local loremipsum = [[Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Elementum curabitur vitae nunc sed. Purus ut faucibus pulvinar elementum integer enim neque volutpat. Venenatis tellus in metus vulputate. Porta non pulvinar neque laoreet suspendisse interdum. Nulla aliquet porttitor lacus luctus accumsan tortor posuere. Consequat nisl vel pretium lectus quam id leo. Egestas purus viverra accumsan in nisl nisi scelerisque eu ultrices. Odio aenean sed adipiscing diam. Viverra orci sagittis eu volutpat odio facilisis mauris.

--   In vitae turpis massa sed elementum tempus egestas sed. Gravida dictum fusce ut placerat. Sit amet mauris commodo quis. Mi proin sed libero enim sed faucibus turpis in eu. Ac turpis egestas integer eget aliquet. Suspendisse interdum consectetur libero id faucibus nisl tincidunt eget nullam. Sollicitudin aliquam ultrices sagittis orci a. Libero enim sed faucibus turpis in eu mi bibendum neque. Pharetra sit amet aliquam id diam maecenas ultricies mi eget. Ut diam quam nulla porttitor massa id. Ipsum consequat nisl vel pretium lectus quam id. Metus vulputate eu scelerisque felis imperdiet proin fermentum leo vel. Volutpat diam ut venenatis tellus. Dui ut ornare lectus sit. Adipiscing at in tellus integer feugiat scelerisque.

--   Ipsum consequat nisl vel pretium lectus quam id leo in. Porta non pulvinar neque laoreet suspendisse interdum consectetur libero. Congue nisi vitae suscipit tellus mauris. Sit amet cursus sit amet dictum. Neque aliquam vestibulum morbi blandit cursus risus at ultrices. Lectus arcu bibendum at varius vel pharetra vel turpis nunc. Velit aliquet sagittis id consectetur purus ut. Elementum sagittis vitae et leo duis ut diam. Dictumst quisque sagittis purus sit amet volutpat consequat mauris. Ut tellus elementum sagittis vitae et. At tellus at urna condimentum mattis pellentesque. Ultrices sagittis orci a scelerisque. Proin fermentum leo vel orci porta non. Sit amet nisl suscipit adipiscing. Aliquam etiam erat velit scelerisque in dictum. Elit ullamcorper dignissim cras tincidunt lobortis feugiat. Urna cursus eget nunc scelerisque viverra mauris in aliquam sem.

--   Congue eu consequat ac felis donec et. Nec nam aliquam sem et tortor. Cras semper auctor neque vitae tempus quam pellentesque nec nam. Fermentum dui faucibus in ornare quam. Nisi scelerisque eu ultrices vitae. Etiam tempor orci eu lobortis elementum nibh tellus molestie. Vitae sapien pellentesque habitant morbi tristique senectus et netus. Non odio euismod lacinia at quis. Venenatis cras sed felis eget. Tincidunt id aliquet risus feugiat in ante metus dictum. Aliquam sem et tortor consequat id porta. Urna id volutpat lacus laoreet non curabitur. In hendrerit gravida rutrum quisque non tellus orci. Est velit egestas dui id ornare arcu odio ut sem. Morbi tristique senectus et netus et malesuada. Integer malesuada nunc vel risus commodo viverra maecenas accumsan lacus. Diam quam nulla porttitor massa id neque aliquam vestibulum morbi. Nisi est sit amet facilisis. Metus aliquam eleifend mi in nulla posuere sollicitudin aliquam.

--   In nisl nisi scelerisque eu ultrices vitae. Donec enim diam vulputate ut pharetra. Pulvinar elementum integer enim neque volutpat. Nunc pulvinar sapien et ligula ullamcorper malesuada proin libero. In hac habitasse platea dictumst quisque sagittis purus sit. Donec ac odio tempor orci dapibus ultrices in. Pulvinar elementum integer enim neque volutpat ac tincidunt. Felis eget nunc lobortis mattis aliquam faucibus. Lectus vestibulum mattis ullamcorper velit sed ullamcorper morbi tincidunt. Dui nunc mattis enim ut tellus. Amet volutpat consequat mauris nunc congue nisi vitae suscipit. Leo integer malesuada nunc vel.]]

-- Temporarily store an id here to use it with the onclick functions
local currentDemoId = nil

local function button_Back()
  addon.MainMenu:Show("demo")
end

local function button_Accept()
  local demo = addon.QuestDemos:GetDemoByID(currentDemoId)
  if not demo then
    addon.Logger:Error("No demo available with id:", currentDemoId)
    return
  end
  local parameters = addon.QuestEngine:Compile(demo.script)
  local quest = addon.QuestEngine:NewQuest(parameters)
  quest:StartTracking()
  addon.QuestEngine:Save()
end

local function button_CopyToDrafts()
  addon.Logger:Warn("Copy to Drafts - Feature not implemented!")
end

function menu:Create(parent)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetAllPoints(true)
  frame:Hide()

  local buttonPane = addon.CustomWidgets:CreateWidget("ButtonPane", frame, "BOTTOM")
  -- bug: This should default to LEFT anchor, but it's defaulting to TOP for some reason? Investigate...
  buttonPane:AddButton("Back", button_Back, { anchor = "LEFT" })
  buttonPane:AddButton("Accept", button_Accept, { anchor = "RIGHT" })
  buttonPane:AddButton("Copy to Drafts", button_CopyToDrafts, { anchor = "RIGHT" })

  local editBoxFrame = CreateFrame("Frame", nil, frame)
  editBoxFrame:SetPoint("TOPLEFT", frame, "TOPLEFT")
  editBoxFrame:SetPoint("BOTTOMRIGHT", buttonPane, "TOPRIGHT")

  local scrollingEditBox = addon.CustomWidgets:CreateWidget("ScrollingEditBox", editBoxFrame)
  scrollingEditBox.editBox:Disable()

  frame.scrollingEditBox = scrollingEditBox

  return frame
end

function menu:OnShow(frame, demoId)
  currentDemoId = demoId
  local demo = QuestDemos:GetDemoByID(demoId)
  if not demo then
    addon.Logger:Error("No demo available with id:", demoId)
  end
  -- frame.scrollingEditBox.editBox:SetText(loremipsum)
  frame.scrollingEditBox.editBox:SetText(demo.script)
end

function menu:OnHide(frame)
  currentDemoId = nil
end
