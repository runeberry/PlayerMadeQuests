local _, addon = ...
local CreateFrame, UIParent = addon.G.CreateFrame, addon.G.UIParent
local assertf, asserttype = addon.assertf, addon.asserttype

local frameTemplates = {} -- Frame creation instructions, indexed by frameType
local frames = {} -- Instances of created frames, indexed by frameName

--- Default methods to be applied to every frame template (not instance) when it's registered.
local templateMethods = {
  ["Create"] = function()
    -- All templates should override this method
    error("Frame template must implement method: Create")
  end,
  ["AfterCreate"] = function()
    -- no-op by default
  end,
  ["AddMethods"] = function(template, methods)
    if type(methods) ~= "table" then
      addon.UILogger:Error("AddMethods: must receive a methods table")
      return
    end

    template._methods = methods
  end,
  ["RegisterCustomScriptEvent"] = function(template, scriptType)
    if type(scriptType) ~= "string" then
      addon.UILogger:Error("RegisterCustomScriptEvent, must received a scriptType")
      return
    end

    template._customScripts[scriptType] = true
  end,
  --- Accepts both Blizzard events and custom script events
  --- See the function "applyScripts" below for how this is handled
  ["AddScripts"] = function(template, scripts)
    if type(scripts) ~= "table" then
      addon.UILogger:Error("AddScripts: must receive a scripts table")
      return
    end

    template._scripts = scripts
  end,
}

local frameMethods = {
  ["HasCustomScript"] = function(frame, scriptType)
    asserttype(scriptType, "string", "scriptType", "HasCustomScript")

    return frame._customScripts[scriptType] and true
  end,
  ["SetCustomScript"] = function(frame, scriptType, handler)
    asserttype(scriptType, "string", "scriptType", "SetCustomScript")
    asserttype(handler, "function", "handler", "SetCustomScript")

    local customScripts = frame._customScripts[scriptType]
    if not customScripts then
      addon.UILogger:Error("SetCustomScript: %s is not recognized for frame %s", scriptType, frame:GetName())
      return
    end

    customScripts[#customScripts+1] = handler
  end,
  ["FireCustomScriptEvent"] = function(frame, scriptType, ...)
    asserttype(scriptType, "string", "scriptType", "FireCustomScriptEvent")

    local customScripts = frame._customScripts[scriptType]
    if not customScripts then
      addon.UILogger:Error("FireCustomScriptEvent: %s is not recognized for frame %s", scriptType, frame:GetName())
      return
    end

    for _, handler in ipairs(customScripts) do
      addon:catch(handler, frame, ...)
    end
  end,
}

--- Throws an error if the provided arg is not recognized as a UI frame.
local function assertIsFrame(frame)
  asserttype(frame, "table", "frame", "assertIsFrame", 2)
  if type(frame.RegisterEvent) ~= "function" then
    error("assertIsFrame: frame does not appear to be a UI Frame", 2)
  end
end

--- Applies a table of scripts to the provided frame.
local function applyScripts(frame, template)
  assertIsFrame(frame)

  -- Create tables to hold any custom script handlers for this frame,
  -- since they won't be managed by SetScript.
  frame._customScripts = {}
  for customScriptType in pairs(template._customScripts) do
    frame._customScripts[customScriptType] = {}
  end

  for scriptType, handler in pairs(template._scripts) do
    local customScripts = frame._customScripts[scriptType]
    if frame:HasCustomScript(scriptType) then
      -- If this is a handler for a registered custom event, store it to be called
      -- when that event is triggered with FireCustomScriptEvent
      frame:SetCustomScript(scriptType, handler)
    else
      -- Otherwise, assume this is a standard Blizzard UI script event
      frame:SetScript(scriptType, handler)
    end
  end
end

--- Registers a new type of UI frame for PMQ.
--- @param frameType string A unique type name for the frame
function addon:NewFrame(frameType)
  local frameTemplate = {
    _methods = {},         -- table{string:function} Additional methods applied to this type of frame
    _scripts = {},         -- table{string:function} Standard Blizzard events set when each instance is created
    _customScripts = {},   -- table{string:bool} Custom UI events that can be trigger with FireCustomScriptEvent
  }
  addon:ApplyMethods(frameTemplate, templateMethods)

  -- Always return the template even if validation fails, so we don't get null refs during file load
  if type(frameType) ~= "string" then
    addon.UILogger:Error("Failed to create NewFrame: frameType is required")
    return frameTemplate
  end
  if frameTemplates[frameType] then
    addon.UILogger:Error("Failed to create NewFrame: frameType \"%s\" already exists", frameType)
    return frameTemplate
  end

  -- But only register the frame if validation was successful
  frameTemplates[frameType] = frameTemplate
  return frameTemplate
end

--- Creates a new instance of a UI frame. Checks if this is custom PMQ frame first,
--- otherwise tries to make a standard Blizzard UI frame.
--- @param frameType string The type of frame to create
--- @param frameName string The unique global name (or name pattern) for this instance of the frame
--- @param parent table A UI frame to act as the created frame's parent
--- Additional args will be passed to the frame template's "Create" function, or "CreateFrame" for Blizzard frames
function addon:CreateFrame(frameType, frameName, parent, ...)
  asserttype(frameType, "string", "frameType", "CreateFrame")
  asserttype(frameName or "", "string", "frameName", "CreateFrame")

  -- Set the default parent if one was not provided
  if not parent then
    parent = UIParent
  else
    assertIsFrame(parent)
  end

  -- Generate a unique global name for this frame
  frameName = frameName or frameType.."%i"
  frameName = addon:CreateGlobalName(frameName)
  assertf(not frames[frameName], "CreateFrame: the frame name \"%s\" is already in use", frameName)

  -- First, check to see if this is a custom PMQ frame
  local frame
  local template = frameTemplates[frameType]
  if template then
    -- If this type was registered with NewFrame, then create it using the template's custom method
    frame = template:Create(frameName, parent, ...)
    assertIsFrame(frame)

    -- Apply any custom methods and scripts registered for this template
    addon:ApplyMethods(frame, frameMethods)
    addon:ApplyMethods(frame, template._methods)
    applyScripts(frame, template)

    -- Finally, the frame is fully formed, finish it up
    template:AfterCreate(frame)
  else
    -- Otherwise, assume this is a standard Blizzard UI frame type
    frame = CreateFrame(frameType, frameName, parent, ...)
  end

  -- Index this frame by name for future reference
  frames[frameName] = frame
  return frame
end