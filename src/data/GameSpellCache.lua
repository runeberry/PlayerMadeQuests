local _, addon = ...
local asserttype = addon.asserttype

--- Caches in-game spells by name so that you can look up their ids
addon.GameSpellCache = addon:NewRepository("GameSpells", "name")
addon.GameSpellCache:SetSaveDataSource("GameSpellCache")
addon.GameSpellCache:EnableWrite(true)
addon.GameSpellCache:EnableDirectRead(true)
addon.GameSpellCache:EnableCompression(false)
addon.GameSpellCache:EnableGlobalSaveData(true)

--- Returns one (arbitrary) spellId associated with a spellName
--- or nil if the spellName is not in the cache
function addon.GameSpellCache:FindSpellID(spellName)
  asserttype(spellName, "string", "spellName", "GetSpellID")

  local entry = self:FindByID(spellName:lower())
  if not entry then return end

  return entry.ids[1]
end

--- Returns an array with all known spellIds associated with a spellName
--- or nil if the spellName is not in the cache
function addon.GameSpellCache:FindSpellIDList(spellName)
  asserttype(spellName, "string", "spellName", "GetSpellIDList")

  local entry = self:FindByID(spellName:lower())
  if not entry then return end

  return entry.ids
end

function addon.GameSpellCache:SaveSpellID(spellName, spellId)
  asserttype(spellName, "string", "spellName", "SaveSpellID")
  asserttype(spellId, "number", "spellId", "SaveSpellID")

  spellName = spellName:lower()
  local entry = self:FindByID(spellName)

  if not entry then
    -- Save a new cache entry if this is a new spell name
    self:Save({ name = spellName, ids = { spellId } })
    return
  end

  for _, id in ipairs(entry.ids) do
    if id == spellId then return end
  end

  -- Update the cache if this is a new id for the spell
  entry.ids[#entry.ids+1] = spellId
  -- Don't need to save since this Repository is direct-read
end