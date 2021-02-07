local _, addon = ...
local CreateFrame, UIParent = addon.G.CreateFrame, addon.G.UIParent
local assertf, asserttype = addon.assertf, addon.asserttype

local frameTemplates = {} -- Widget creation instructions, indexed by widgetType
local frames = {} -- Instances of created frames, indexed by frameName

--- Default methods to be applied to every widget template (not instance) when it's created.
local templateMethods = {
  ["Create"] = function()
    -- All templates should override this method
    error("Widget template must implement method: Create")
  end
}

--- Throws an error if the provided arg is not recognized as a UI frame.
local function assertIsFrame(frame)
  asserttype(frame, "table", "frame", "assertIsFrame", 2)
  if type(frame.RegisterEvent) ~= "function" then
    error("assertIsFrame: frame does not appear to be a UI Frame", 2)
  end
end

--- Registers a new type of UI frame for PMQ.
--- @param frameType string A unique type name for the frame
function addon:NewFrame(frameType)
  local frameTemplate = {}
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
--- @param frameName string The unique global name (or name pattern) for this instance of the widget
--- @param parent table A UI frame to act as the created frame's parent
--- Additional args will be passed to the frame template's "Create" function, or "CreateFrame" for Blizzard frames
function addon:CreateFrame(frameType, frameName, parent, ...)
  asserttype(frameType, "string", "widgetType", "CreateFrame")
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

  -- First, check to see if this is a custom PMQ widget
  local frame
  local template = frameTemplates[frameType]
  if template then
    -- If this type was registered with NewWidget, then create it using the custom method
    frame = template:Create(frameName, parent, ...)
    assertIsFrame(frame)
  else
    -- Otherwise, assume this is a standard Blizzard UI frame type
    frame = CreateFrame(frameType, frameName, parent, ...)
  end

  -- Index this frame by name for future reference
  frames[frameName] = frame
  return frame
end

--- Applies a table of scripts to the provided frame.
--- @param frame table A UI frame
--- @param scripts table A table of eventName:handlerFunc
function addon:ApplyScripts(frame, scripts)
  assertIsFrame(frame)

  for eventName, handler in pairs(scripts) do
    frame:SetScript(eventName, handler)
  end
end