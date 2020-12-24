local _, addon = ...
local Ace, LibCompress = addon.Ace, addon.LibCompress

-- Gets the length of a table (top-level only), for troubleshooting
function addon:tlen(t)
  if t == nil then return 0 end
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

-- Removes all fields that are not of type: string, number, boolean, or table
-- Removes all fields that begin with _
-- May not play well with array tables... idk!
function addon:CleanTable(t, circ)
  if t == nil then error("Cannot clean a nil table") end
  circ = circ or {}
  circ[t] = true -- Ensure the provided table won't get cleaned twice
  local ktype, vtype
  for k, v in pairs(t) do
    ktype = type(k)
    vtype = type(v)
    if ktype == "string" and k:match("^_") then
      -- Remove any values whose key starts with '_'
      t[k] = nil
    elseif vtype == "table" then
      -- Any inner tables will also be cleaned
      if not circ[v] then
        self:CleanTable(v, circ)
      end
    elseif vtype == "string" or vtype == "number" or vtype == "boolean" then
      -- Any values of type string, number, or boolean are left as-is
    else
      -- Remove any values of any other type (like functions)
      t[k] = nil
    end
  end
  return t
end

-- Performs a deep copy of the table and all subtables
-- References to functions will not be changed
function addon:CopyTable(t, circ)
  if t == nil then error("Cannot copy a nil table") end
  circ = circ or {}
  local copy = {}
  circ[t] = copy -- Ensure the provided table won't get copied twice
  for k, v in pairs(t) do
    if type(v) == "table" then
      if circ[v] then
        -- Use the same copy for each instance of the same inner table
        copy[k] = circ[v]
      else
        copy[k] = self:CopyTable(v, circ)
      end
    else
      copy[k] = v
    end
  end
  return copy
end

-- Performs a recursive table merge of t2 onto t1
-- If any fields collide, t2 will overwrite t1
-- Returns a new table - does not modify t1 or t2
function addon:MergeTable(t1, t2, circ)
  if t1 == nil or t2 == nil then error("Cannot merge a nil table") end
  local merged = self:CopyTable(t1)
  circ = circ or {}
  circ[t1] = merged -- Ensure that both provided tables will only be merged once
  circ[t2] = merged
  circ[merged] = merged -- Ensure that any references to the merged table are not re-merged
  for _, v in ipairs(t2) do
    -- Append all array-like items onto t1's array-like list
    if type(v) == "table" then
      merged[#merged+1] = self:CopyTable(v)
    else
      merged[#merged+1] = v
    end
  end
  for k, v in pairs(t2) do
    if type(k) == "number" then
      -- Do nothing, this was already "appended" during ipairs
    elseif type(v) == "table" then
      if circ[v] then
        merged[k] = circ[v]
      elseif type(merged[k]) == "table" then
        -- If t1 and t2 both have tables at index k,
        -- then merge the two subtables and assign the result
        merged[k] = self:MergeTable(merged[k], v, circ)
      else
        -- Otherwise, t2's subtable simply overwrites t1's value
        merged[k] = self:CopyTable(v, circ)
      end
    else
      merged[k] = v
    end
  end
  return merged
end

--- Extension of MergeOptions that will return a copy of defaultOptions
--- if there are no custom options provided.
function addon:MergeOptionsTable(defaultOptions, ...)
  assert(defaultOptions ~= nil, "MergeOptionsTable: defaultOptions cannot be nil")
  assert(type(defaultOptions) == "table", "MergeOptionsTable: defaultOptions must be a table, got type "..type(defaultOptions))

  local customOptionsTables = { ... }
  local merged = defaultOptions

  if #customOptionsTables == 0 then
    merged = addon:CopyTable(defaultOptions)
  else
    for _, customOptions in ipairs(customOptionsTables) do
      assert(type(customOptions) == "table", "MergeOptionsTable: customOptions must be a table, got type "..type(customOptions))
      merged = addon:MergeTable(merged, customOptions)
    end
  end

  return merged
end

--- Copies a table of methods to an object
function addon:ApplyMethods(obj, methods, force)
  assert(obj ~= nil, "ApplyMethods: cannot apply methods to a nil object")
  assert(type(obj) == "table", "ApplyMethods: object must be a table, got type: "..type(obj))
  assert(methods ~= nil, "ApplyMethods: cannot apply nil method table to an object")
  assert(type(methods) == "table", "ApplyMethods: methods must be a table, got type: "..type(methods))

  for fname, fn in pairs(methods) do
    if type(fname) == "string" and type(fn) == "function" then
      if not force and obj[fname] ~= nil then
        addon.Logger:Error("ApplyMethods: method name '%s' is already taken on this object", fname)
      else
        obj[fname] = fn
      end
    end
  end
end

function addon:DistinctSet(t)
  if t == nil then error("Cannot create a set from a nil table") end
  local set, i = {}, 0
  for _, item in pairs(t) do
    set[item] = true
    i = i + 1
  end
  return set, i
end

function addon:SetToArray(set)
  if set == nil then error("Cannot convert a nil set to an array") end
  local array, i = {}, 0
  for item in pairs(set) do
    table.insert(array, item)
    i = i + 1
  end
  return array, i
end

function addon:InvertTable(t)
  if t == nil then error("Cannot invert a nil table") end
  local inverted, i = {}, 0
  for k, v in pairs(t) do
    inverted[v] = k
    i = i + 1
  end
  return inverted, i
end

-- Adapted from: https://stackoverflow.com/a/15278426/7071436
function addon:ConcatArray(t1, t2)
  if t1 == nil or t2 == nil then error("Cannot concat nil tables") end
  for i = 1, #t2 do
    t1[#t1+1] = t2[i]
  end
  return t1
end

function addon:CompressTable(t)
  if t == nil then error("Cannot compress a nil table") end
  local cleaned = addon:CleanTable(addon:CopyTable(t))
  local serialized = Ace:Serialize(cleaned)
  local compressed = LibCompress:CompressHuffman(serialized)
  return compressed
end

function addon:DecompressTable(str)
  if str == nil or str == "" then
    return {}
  end

  local serialized, msg = LibCompress:Decompress(str)
  if serialized == nil then
    addon.Logger:Error("Failed to decompress table: %s", msg)
    return {}
  end

  local ok, t = Ace:Deserialize(serialized)
  if not ok then
    -- 2nd param is an error message if it failed
    addon.Logger:Error("Failed to deserialize table: %s", t)
    return {}
  end

  return t
end

--- Returns a 32-bit hash value representing the contents of the table
--- @param t table
--- @return number (float)
function addon:GetTableHash(t)
  assert(type(t) == "table", "Must provide a table to hash")
  local serialized = Ace:Serialize(t)
  local hash = LibCompress:fcs32init()
  hash = LibCompress:fcs32update(hash, serialized)
  hash = LibCompress:fcs32final(hash)
  return hash
end

-- Unpacks either format { r = r, g = g, b = b, a = a } or { r, g, b, a }
function addon:UnpackRGBA(t)
  if not t then
    return 0.0, 0.0, 0.0, 1.0
  elseif type(t) == "number" then
    return t, t, t, 1.0
  elseif t.r or t.g or t.b or t.a then
    return t.r or 0.0, t.g or 0.0, t.b or 0.0, t.a or 1.0
  else
    return t[1] or 0.0, t[2] or 0.0, t[3] or 0.0, t[4] or 1.0
  end
end

-- Unpacks either format { l = l, r = r, t = t, b = b } or { l, r, t, b }
function addon:UnpackLRTB(t)
  if not t then
    return 0, 0, 0, 0
  elseif type(t) == "number" then
    return t, t, t, t
  elseif t.l or t.r or t.t or t.b then
    return t.l or 0, t.r or 0, t.t or 0, t.b or 0
  else
    return t[1] or 0, t[2] or 0, t[3] or 0, t[4] or 0
  end
end

-- Unpacks either format { x = x, y = y } or { x, y }
function addon:UnpackXY(t)
  if not t then
    return 0.0, 0.0
  elseif type(t) == "number" then
    return t, t
  elseif t.x or t.y then
    return t.x or 0.0, t.y or 0.0
  else
    return t[1] or 0.0, t[2] or 0.0
  end
end