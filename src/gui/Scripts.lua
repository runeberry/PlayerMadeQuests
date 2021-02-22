local _, addon = ...
local asserttype, assertframe = addon.asserttype, addon.assertframe

local function applyScript(frame, scriptType, handler)
  if frame.HasCustomScript and frame:HasCustomScript(scriptType) then
    -- If this is a handler for a registered custom event, store it to be called
    -- when that event is triggered with FireCustomScriptEvent
    frame:SetCustomScript(scriptType, handler)
  else
    -- Otherwise, assume this is a standard Blizzard UI script event
    frame:SetScript(scriptType, handler)
  end
end

--- Applies a standard or PMQ-custom script handler to a UI frame.
--- @param scriptType string The UI event to hook into. Can be a standard Blizzard event or a custom PMQ event.
--- @param handler function The function to run when the event is fired.
function addon:ApplyScript(frame, scriptType, handler)
  assertframe(frame, "frame", "ApplyScripts")
  asserttype(scriptType, "string", "scriptType", "ApplyScript")
  asserttype(handler, "function", "handler", "ApplyScript")

  applyScript(frame, scriptType, handler)
end

--- Applies a table of scripts to the provided frame, where key = ScriptType
--- like "OnShow", and value is a function to handle that event. Can accept
--- custom script events register on PMQ widget templates or basic Blizzard events.
--- @param frame table A UI frame to set scripts on
--- @param scripts table A table of scripts
function addon:ApplyScripts(frame, scripts)
  assertframe(frame, "frame", "ApplyScripts")
  asserttype(scripts, "table", "scripts", "ApplyScripts")

  for scriptType, handler in pairs(scripts) do
    applyScript(frame, scriptType, handler)
  end
end