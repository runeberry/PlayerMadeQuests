local _, addon = ...

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
  circ = circ or {}
  circ[t] = true -- Ensure the provided table won't get cleaned twice
  local ktype, vtype
  for k, v in pairs(t) do
    ktype = type(k)
    vtype = type(v)
    if ktype == "string" and k:match("^_") then
      -- Remove the value
      t[k] = nil
    elseif vtype == "table" then
      if not circ[v] then
        self:CleanTable(v, circ)
      end
    elseif vtype == "string" or vtype == "number" or vtype == "boolean" then
      -- Leave the value alone
    else
      -- Remove the value
      t[k] = nil
    end
  end
  return t
end

-- Performs a deep copy of the table and all subtables
-- References to functions will not be changed
function addon:CopyTable(t, circ)
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
  local merged = self:CopyTable(t1)
  circ = circ or {}
  circ[t1] = merged -- Ensure that both provided tables will only be merged once
  circ[t2] = merged
  circ[merged] = merged -- Ensure that any references to the merged table are not re-merged
  for k, v in pairs(t2) do
    if type(v) == "table" then
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