local _, addon = ...

local condition = addon.QuestEngine:NewCondition(addon.QuestScriptTokens.PARAM_LANGUAGE)
condition:AllowType("string")
condition:AllowMultiple(true)

function condition:OnParse(arg)
  if type(arg) == "string" then
    arg = { arg }
  end

  -- Lowercase all args for case-insensitive comparison
  for i, v in ipairs(arg) do
    if v then
      arg[i] = v:lower()
    end
  end

  return addon:DistinctSet(arg)
end

function condition:Evaluate(languages)
  -- Get the language of the last chat message spoken by the player
  local lang = addon.LastChatLanguage

  if not lang then
    self.logger:Fail("Chat not spoken in an RP language")
    return false
  end

  if languages[lang] then
    self.logger:Pass("Chat spoken in language: %s", lang)
    return true
  end

  self.logger:Fail("Chat spoken in language: %s", lang)
  return false
end