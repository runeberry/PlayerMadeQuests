local _, addon = ...

--- Define this function below to do whatever you want on startup
local sandbox

addon:OnAddonReady(function()
  if not addon.Config:GetValue("ENABLE_SANDBOX") then return end
  addon.Logger:Debug("Sandbox enabled.")
  addon:catch(sandbox)
end)

sandbox = function()

end