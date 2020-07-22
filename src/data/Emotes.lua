local _, addon = ...

addon.Emotes = addon:NewRepository("Emote", "command")
addon.Emotes:AddIndex("targeted")
addon.Emotes:AddIndex("untargeted")
addon.Emotes:SetTableSource(addon.EmoteDB)

function addon.Emotes:FindByCommand(cmd)
  if not(cmd:match("^/")) then
    cmd = "/"..cmd
  end

  return self:FindByID(cmd)
end