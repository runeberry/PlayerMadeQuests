local _, addon = ...

local colors = {
  red = "ffff0000",
  green = "ff1eff00",
  blue = "ff0070dd",
  grey = "ff9d9d9d",
  white = "ffffffff",
  black = "ff000000",
  purple = "ffa335ee",
  orange = "ffff8000",
  yellow = "ffffff00"
}

-- Use the mapped color if available, otherwise assume the string is an 8-char hex string
-- If no color is specified, default to white
function addon:GetEscapeColor(color)
  return "|c"..(colors[color] or color or colors.white)
end

function addon:Colorize(color, str)
  return addon:GetEscapeColor(color)..str.."|r"
end

function addon:Pluralize(num, singular, plural)
  if num == 1 then
    return singular
  else
    -- If no plural is provided, you get lazy pluralization
    return plural or singular.."s"
  end
end

-- Adapted from the CSV parser found here: http://lua-users.org/wiki/LuaCsv
-- function addon:strWords(line)
--   local res = {}
--   local pos = 1
--   local sep = " "
--   while true do
--     local c = string.sub(line,pos,pos)
--     if (c == "") then break end
--     if (c == '"') then
--       -- quoted value (ignore separator within)
--       local txt = ""
--       repeat
--         local startp,endp = string.find(line,'^%b""',pos)
--         txt = txt..string.sub(line,startp+1,endp-1)
--         pos = endp + 1
--         c = string.sub(line,pos,pos)
--         if (c == '"') then txt = txt..'"' end
--         -- check first char AFTER quoted string, if it is another
--         -- quoted string without separator, then append it
--         -- this is the way to "escape" the quote char in a quote. example:
--         --   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
--       until (c ~= '"')
--       table.insert(res,txt)
--       assert(c == sep or c == "")
--       pos = pos + 1
--     elseif (c == "'") then -- jb: this parser supports single and double quotes
--       -- quoted value (ignore separator within)
--       local txt = ""
--       repeat
--         local startp,endp = string.find(line,"^%b''",pos)
--         txt = txt..string.sub(line,startp+1,endp-1)
--         pos = endp + 1
--         c = string.sub(line,pos,pos)
--         if (c == "'") then txt = txt.."'" end
--         -- check first char AFTER quoted string, if it is another
--         -- quoted string without separator, then append it
--         -- this is the way to "escape" the quote char in a quote. example:
--         --   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
--       until (c ~= "'")
--       table.insert(res,txt)
--       assert(c == sep or c == "")
--       pos = pos + 1
--     else
--       -- no quotes used, just look for the first separator
--       local startp,endp = string.find(line,sep,pos)
--       if (startp) then
--         table.insert(res,string.sub(line,pos,startp-1))
--         pos = endp + 1
--       else
--         -- no separator found -> use rest of string and terminate
--         table.insert(res,string.sub(line,pos))
--         break
--       end
--     end
--   end
--   return res
-- end