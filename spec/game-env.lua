local mock = require("spec/mock")

local game = {}

function game:ResetEnv(addon)
  addon._genv_aura_index = nil

  mock:GetFunctionMock(addon.G.UnitAura):Reset()
end

function game:AddPlayerAura(addon, aura)
  assert(type(aura) == "table", "AddPlayerAura must receive a table")

  local ret = {
    aura.name,
    aura.icon,
    aura.count,
    aura.debuffType,
    aura.duration,
    aura.expirationTime,
    aura.source,
    aura.isStealable,
    aura.nameplateShowPersonal,
    aura.spellId,
    aura.canApplyAura,
    aura.isBossDebuff,
    aura.castByPlayer,
    aura.nameplateShowAll,
    aura.timeMod,
  }

  local index = addon._genv_aura_index or 0
  index = index + 1
  addon._genv_aura_index = index

  local auraMock = mock:GetFunctionMock(addon.G.UnitAura)
  auraMock:SetReturnsWhen(function(uid, idx)
    return uid == "player" and idx == index
  end, table.unpack(ret))
end

function game:SetPlayerTarget(addon, targetName)
  local targetMock = mock:GetFunctionMock(addon.G.GetUnitName)
  targetMock:SetReturnsWhen(function(uid) return uid == "target" end, targetName)
end

return game