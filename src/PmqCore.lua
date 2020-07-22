local _, addon = ...
local print = addon.G.print

addon.VERSION = 4
addon.BRANCH = "alpha"
addon.IsAddonLoaded = false

function addon.Ace:OnInitialize()
  addon:catch(function()
    -- addon.Logger:NewLogger("test")
    addon.IsAddonLoaded = true
    addon:load()
    addon.SaveData:Init()
    addon.Logger:Info("PlayerMadeQuests loaded. Type "..addon:Colorize("orange", "/pmq").." to open the main menu.")
  end)
end

function addon.Ace:OnEnable()

end

function addon.Ace:OnDisable()

end

-- Runs the provided function, catching any Lua errors and logging them to console
-- Returns up to 4 values... not sure how to effectively make this dynamic
function addon:catch(fn, ...)
  local ok, result, r2, r3, r4 = pcall(fn, ...)
  if not(ok) then
    -- Uncomment this as an escape hatch to print errors if logging breaks
    -- print("Lua script error") if result then print(result) end
    addon.Logger:Error("Lua script error:", result)
  end
  return ok, result, r2, r3, r4
end

-- Defer code execution until the addon is fully loaded
local _onloadBuffer = {}
function addon:onload(fn)
  table.insert(_onloadBuffer, fn)
end

function addon:load()
  if _onloadBuffer == nil then return end
  for _, fn in pairs(_onloadBuffer) do
    local ok, err = pcall(fn)
    if not ok then
      print("[PMQ:onload] Startup error:", err)
    end
  end
  _onloadBuffer = nil
end

function addon:OnSaveDataLoaded(fn)
  if addon.SaveDataLoaded then
    -- If save data is already loaded, run the function now
    fn()
  elseif not _onloadBuffer then
    -- If the onload buffer has already been flushed, but save data is
    -- not loaded, then subscribe directly to the SaveDataLoaded event
    addon.AppEvents:Subscribe("SaveDataLoaded", fn)
  else
    -- Otherwise, subscribe to SaveDataLoaded only after the addon has
    -- fully loaded
    addon:onload(function()
      addon.AppEvents:Subscribe("SaveDataLoaded", fn)
    end)
  end
end

-- Long text to use for display testing
addon.LOREM_IPSUM = [[Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Elementum curabitur vitae nunc sed. Purus ut faucibus pulvinar elementum integer enim neque volutpat. Venenatis tellus in metus vulputate. Porta non pulvinar neque laoreet suspendisse interdum. Nulla aliquet porttitor lacus luctus accumsan tortor posuere. Consequat nisl vel pretium lectus quam id leo. Egestas purus viverra accumsan in nisl nisi scelerisque eu ultrices. Odio aenean sed adipiscing diam. Viverra orci sagittis eu volutpat odio facilisis mauris.

In vitae turpis massa sed elementum tempus egestas sed. Gravida dictum fusce ut placerat. Sit amet mauris commodo quis. Mi proin sed libero enim sed faucibus turpis in eu. Ac turpis egestas integer eget aliquet. Suspendisse interdum consectetur libero id faucibus nisl tincidunt eget nullam. Sollicitudin aliquam ultrices sagittis orci a. Libero enim sed faucibus turpis in eu mi bibendum neque. Pharetra sit amet aliquam id diam maecenas ultricies mi eget. Ut diam quam nulla porttitor massa id. Ipsum consequat nisl vel pretium lectus quam id. Metus vulputate eu scelerisque felis imperdiet proin fermentum leo vel. Volutpat diam ut venenatis tellus. Dui ut ornare lectus sit. Adipiscing at in tellus integer feugiat scelerisque.

Ipsum consequat nisl vel pretium lectus quam id leo in. Porta non pulvinar neque laoreet suspendisse interdum consectetur libero. Congue nisi vitae suscipit tellus mauris. Sit amet cursus sit amet dictum. Neque aliquam vestibulum morbi blandit cursus risus at ultrices. Lectus arcu bibendum at varius vel pharetra vel turpis nunc. Velit aliquet sagittis id consectetur purus ut. Elementum sagittis vitae et leo duis ut diam. Dictumst quisque sagittis purus sit amet volutpat consequat mauris. Ut tellus elementum sagittis vitae et. At tellus at urna condimentum mattis pellentesque. Ultrices sagittis orci a scelerisque. Proin fermentum leo vel orci porta non. Sit amet nisl suscipit adipiscing. Aliquam etiam erat velit scelerisque in dictum. Elit ullamcorper dignissim cras tincidunt lobortis feugiat. Urna cursus eget nunc scelerisque viverra mauris in aliquam sem.

Congue eu consequat ac felis donec et. Nec nam aliquam sem et tortor. Cras semper auctor neque vitae tempus quam pellentesque nec nam. Fermentum dui faucibus in ornare quam. Nisi scelerisque eu ultrices vitae. Etiam tempor orci eu lobortis elementum nibh tellus molestie. Vitae sapien pellentesque habitant morbi tristique senectus et netus. Non odio euismod lacinia at quis. Venenatis cras sed felis eget. Tincidunt id aliquet risus feugiat in ante metus dictum. Aliquam sem et tortor consequat id porta. Urna id volutpat lacus laoreet non curabitur. In hendrerit gravida rutrum quisque non tellus orci. Est velit egestas dui id ornare arcu odio ut sem. Morbi tristique senectus et netus et malesuada. Integer malesuada nunc vel risus commodo viverra maecenas accumsan lacus. Diam quam nulla porttitor massa id neque aliquam vestibulum morbi. Nisi est sit amet facilisis. Metus aliquam eleifend mi in nulla posuere sollicitudin aliquam.

In nisl nisi scelerisque eu ultrices vitae. Donec enim diam vulputate ut pharetra. Pulvinar elementum integer enim neque volutpat. Nunc pulvinar sapien et ligula ullamcorper malesuada proin libero. In hac habitasse platea dictumst quisque sagittis purus sit. Donec ac odio tempor orci dapibus ultrices in. Pulvinar elementum integer enim neque volutpat ac tincidunt. Felis eget nunc lobortis mattis aliquam faucibus. Lectus vestibulum mattis ullamcorper velit sed ullamcorper morbi tincidunt. Dui nunc mattis enim ut tellus. Amet volutpat consequat mauris nunc congue nisi vitae suscipit. Leo integer malesuada nunc vel.]]