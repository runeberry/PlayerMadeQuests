local _, addon = ...
local tokens = addon.QuestScriptTokens
local QuestChains = addon.QuestChains

local checkpoint = addon.QuestEngine:NewCheckpoint("chain")
checkpoint:AddParameter("name", { required = true, type = { "string" } })
checkpoint:AddParameter("order", { required = true, type = { "number" } })

function checkpoint:OnValidate(chain)
  if chain.order < 1 then
    error("Chain order must be >= 1")
  end
end

function checkpoint:OnParse(chain)

end