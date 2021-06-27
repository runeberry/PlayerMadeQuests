local _, addon = ...
local CreateFrame, UIParent, unpack = addon.G.CreateFrame, addon.G.UIParent, addon.G.unpack
local assertf, asserttype, assertframe = addon.assertf, addon.asserttype, addon.assertframe

local frameTemplates = {} -- Frame creation instructions, indexed by frameType
local templateMethods
local frameMethods

local function newFrameTemplate(frameType, inheritsFrom, inheritsTemplate)
  local frameTemplate = {
    _frameType = frameType,
    _baseFrameType = nil,   -- string, what type of Blizzard frame to construct this widget from
    _inheritsFrom = inheritsFrom,
    _inheritsTemplate = inheritsTemplate,
    _defaultOptions = {},
    _conditionalOptions = {},
    _inheritanceOrder = {}, -- array{string} Template names in the order of least-specific to most-specific
    _mixins = {},           -- array{string} Mixin template names to apply before running Create
    _methods = {},          -- table{string:function} Additional methods applied to this type of frame
    _scripts = {},          -- array{table{string:function}} Script handlers indexed by the order they were added
    _customEvents = {},     -- table{string:bool} Custom UI events that can be trigger with FireCustomScriptEvent
  }
  addon:ApplyMethods(frameTemplate, templateMethods)

  -- All custom frames have a Refresh method, which calls the OnRefresh events
  frameTemplate:RegisterCustomScriptEvent("OnRefresh")
  frameTemplate:RegisterCustomScriptEvent("AfterRefresh")

  return frameTemplate
end

--- Default methods to be applied to every frame template (not instance) when it's registered.
templateMethods = {
  ["Create"] = function()
    -- All templates should override this method
    error("Frame template must implement method: Create")
  end,
  ["SetDefaultOptions"] = function(template, options)
    if type(options) ~= "table" then
      addon.UILogger:Error("SetDefaultOptions: options must be a table")
      return
    end

    template._defaultOptions = options
  end,
  ["SetConditionalOptions"] = function(template, optionName, optionsByValue)
    if type(optionName) ~= "string" then
      addon.UILogger:Error("SetConditionalOptions: optionName must be provided")
      return
    end

    if type(optionsByValue) ~= "table" then
      addon.UILogger:Error("SetConditionalOptions: options must be a table of { ['value at optionName'] = { } }")
      return
    end

    for k, v in pairs(optionsByValue) do
      if type(v) ~= "table" then
        addon.UILogger:Error("SetConditionalOptions: options must be a table of { ['value at optionName'] = { } }")
        return
      end
    end

    template._conditionalOptions[#template._conditionalOptions+1] = {
      optionName = optionName,
      optionsByValue = optionsByValue,
    }
  end,
  ["AddMethods"] = function(template, methods)
    if type(methods) ~= "table" then
      addon.UILogger:Error("AddMethods: must receive a methods table")
      return
    end

    template._methods = methods
  end,
  ["AddMixin"] = function(template, mixinType)
    -- Can't validate that mixin is a valid frameTemplate at this time
    -- because that would cause this operation to depend on file load order
    if type(mixinType) ~= "string" then
      addon.UILogger:Error("AddMixin: mixinType must be a string")
      return
    end

    -- Ensure that duplicate mixins aren't added to the template
    for _, m in ipairs(template._mixins) do
      if m == mixinType then return end
    end

    template._mixins[#template._mixins+1] = mixinType
  end,
  ["RegisterCustomScriptEvent"] = function(template, scriptType)
    if type(scriptType) ~= "string" then
      addon.UILogger:Error("RegisterCustomScriptEvent: must receive a scriptType")
      return
    end

    template._customEvents[scriptType] = true
  end,
  --- Accepts both Blizzard events and custom script events
  --- See the function "applyScripts" below for how this is handled
  ["AddScripts"] = function(template, scripts)
    if type(scripts) ~= "table" then
      addon.UILogger:Error("AddScripts: must receive a scripts table")
      return
    end

    for scriptType, handler in pairs(scripts) do
      -- This abstraction lets us apply multiple handlers to the same scriptType
      -- over multiple calls to AddScripts
      template._scripts[#template._scripts+1] = {
        scriptType = scriptType,
        handler = handler
      }
    end
  end,
}

frameMethods = {
  ["GetCustomObjectType"] = function(frame)
    return frame._frameType
  end,
  ["IsCustomObjectType"] = function(frame, templateName)
    return frame._frameType == templateName
  end,

  ["HasCustomScript"] = function(frame, scriptType)
    if not frame._frameType then return false end
    if not frameTemplates[frame._frameType] then return false end
    return frameTemplates[frame._frameType]._customEvents[scriptType] or false
  end,
  ["SetCustomScript"] = function(frame, scriptType, handler)
    if not frame:HasCustomScript(scriptType) then return end
    addon.UIEvents:Subscribe(frame, scriptType, handler)
  end,

  ["FireCustomScriptEvent"] = function(frame, scriptType, ...)
    if not frame._frameCreated then
      frame:QueueCustomScriptEvent(frame, scriptType, ...)
      return
    end
    addon.UIEvents:Publish(frame, scriptType, ...)
  end,
  ["QueueCustomScriptEvent"] = function(frame, scriptType, ...)
    frame._scriptEventQueue = frame._scriptEventQueue or {}
    frame._scriptEventQueue[#frame._scriptEventQueue] = {
      scriptType = scriptType,
      args = { ... },
    }
  end,
  ["FlushEventQueue"] = function(frame)
    if not frame._scriptEventQueue or #frame._scriptEventQueue == 0 then return end

    for _, item in ipairs(frame._scriptEventQueue) do
      addon.UIEvents:Publish(frame, item.scriptType, unpack(item.args))
    end
    frame._scriptEventQueue = nil
  end,

  ["Refresh"] = function(frame)
    frame:FireCustomScriptEvent("OnRefresh")
    frame:FireCustomScriptEvent("AfterRefresh")
  end,
  ["GetOptions"] = function(frame)
    return frame._options
  end,
}

--------------------------------
-- FRAME TEMPLATE INHERITANCE --
--------------------------------

local function setInheritanceOrder(template, inTable, inArray)
  inTable = inTable or {}
  inArray = inArray or template._inheritanceOrder

  if template._inheritsFrom then
    local parentTemplate = frameTemplates[template._inheritsFrom]
    if parentTemplate then
      -- Parents will be added first
      setInheritanceOrder(parentTemplate, inTable, inArray)
    end
  end

  -- Mixins will be added in their existing order, always before the template itself
  for _, mixinType in ipairs(template._mixins) do
    if not frameTemplates[mixinType] then
      -- Mixins are not validate on AddMixins, so validate them here
      addon.UILogger:Error("%s is not a valid mixinType for widget %s", mixinType, template._frameType)
    elseif not inTable[mixinType] then
      setInheritanceOrder(frameTemplates[mixinType], inTable, inArray)
    end
  end

  -- Finally, the template itself is last in the list
  -- Ensure that duplicates are not added
  if not inTable[template._frameType] then
    inTable[template._frameType] = true
    inArray[#inArray+1] = template._frameType
  end
end

--- Run the handler in order of "least specific" to "most specific" template
local function forInheritanceOrder(template, handler, skipSelf)
  local i, imax = 1, #template._inheritanceOrder
  if skipSelf then
    imax = imax - 1
  end
  while i <= imax do
    handler(template, frameTemplates[template._inheritanceOrder[i]])
    i = i + 1
  end
end

--- Run the handler in reverse order, from "most specific" to "least specific" template
local function forReverseInheritanceOrder(template, handler, skipSelf)
  local i = #template._inheritanceOrder
  if skipSelf then
    i = i - 1
  end
  while i > 0 do
    handler(template, frameTemplates[template._inheritanceOrder[i]])
    i = i - 1
  end
end

local function setBaseFrameType(template)
  if not template._inheritsFrom then
    -- There is no parent, nothing to inherit
    template._baseFrameType = "Frame"
    return
  end
  local parent = frameTemplates[template._inheritsFrom]
  if not parent then
    -- The parent is not a custom widget, it's a Blizzard frame
    template._baseFrameType = template._inheritsFrom
    return
  end

  -- The parent is a custom widget, so determine its Blizzard frame type
  -- and copy it to this template
  setBaseFrameType(parent)
  template._baseFrameType = parent._baseFrameType
end

local function applyGlobals(template)
  -- All templates have a common set of core methods to apply to frames
  -- If any template attempts to override these methods, an error will be thrown
  addon:ApplyMethods(template._methods, frameMethods)
end

-- t1 is considered "more specific" than t2 (t2 is a parent or mixin)
local function mergeTemplates(t1, t2)
  -- t1 inherits any of the methods applied to t2.
  -- If there's a conflict, methods on t1 will take priority (override).
  for fname, fn in pairs(t2._methods) do
    if not t1._methods[fname] then
      t1._methods[fname] = fn
    end
  end

  -- t1 registers all of the custom script types that are registered with t2
  for k, v in pairs(t2._customEvents) do
    t1._customEvents[k] = v
  end

  -- t1 copies all of the script handlers from t2
  for _, scriptHandlerContainer in ipairs(t2._scripts) do
    t1._scripts[#t1._scripts+1] = scriptHandlerContainer
  end

  -- t1 inherits the default options of t2, but t1's options take priority
  t1._defaultOptions = addon:MergeOptionsTable(t2._defaultOptions, t1._defaultOptions)
end

local function applyInheritance(template)
  forReverseInheritanceOrder(template, mergeTemplates, true)
end

-- Template inheritance can be solved as soon as all custom widget templates are loaded.
-- No need to do this each time a frame is created, but need to wait until all files have been loaded.
addon:OnAddonStart(function()
  for _, template in pairs(frameTemplates) do
    setInheritanceOrder(template)
    setBaseFrameType(template)
    applyGlobals(template)
    applyInheritance(template)
  end
end)

--------------------
-- FRAME CREATION --
--------------------

local function createFrameName(frameType, frameName, parent)
  if not frameName then
    frameName = frameType.."%i"
  else
    local parentName = parent:GetName()
    if parentName then
      -- Blizzard's CreateFrame will do this automatically, but we're doing this in advance
      -- so we can validate that the global name is available
      frameName = string.gsub(frameName, "$parent", parentName)
    end
  end

  frameName = addon:CreateGlobalName(frameName)
  -- Blizzard's CreateFrame automatically indexes all frames as global variables by name
  assertf(not _G[frameName], "CreateFrame: the frame name \"%s\" is already in use", frameName)
  return frameName
end

local function applyConditionalOption(frame, optionName, optionsByValue)
  local value = frame._options[optionName]
  local optionsByThisValue = optionsByValue[value]
  if not optionsByThisValue then return end -- No options specified for this conditional value

  frame._options = addon:MergeOptionsTable(frame._options, optionsByThisValue)
end

local function applyConditionalOptions(frame, template, options)
  if #template._conditionalOptions == 0 then return end

  for _, conditionalOptionsContainer in ipairs(template._conditionalOptions) do
    applyConditionalOption(frame, conditionalOptionsContainer.optionName, conditionalOptionsContainer.optionsByValue)
  end

  -- Options specified for this instance of the frame still take priority
  -- after all conditional options have been applied
  frame._options = addon:MergeOptionsTable(frame._options, options)
end

local function runConditionals(frame, template, options)
  forInheritanceOrder(template, function(_, t2)
    applyConditionalOptions(frame, t2, options)
  end)
end

local function runCreate(frame, template)
  -- Create method call order is determined ahead-of-time and saved to the template
  forInheritanceOrder(template, function(_, t2)
    t2:Create(frame, frame._options)
  end)
end

local function createCustomFrame(frameType, frameName, parent, options)
  local template = frameTemplates[frameType]

  -- STEP 1: Create the Blizzard frame that will ultimately be the parent (root) of any custom widget.
  local frame = CreateFrame(template._baseFrameType, frameName, parent, template._inheritsTemplate)

  -- Give the frame a reference to its own template for the following operations
  frame._frameType = frameType

  -- STEP 2: Apply non-dependent static data
  addon:ApplyMethods(frame, template._methods)
  for _, scriptHandlerContainer in ipairs(template._scripts) do
    addon:ApplyScript(frame, scriptHandlerContainer.scriptType, scriptHandlerContainer.handler)
  end
  frame._options = addon:MergeOptionsTable(template._defaultOptions, options)

  -- STEP 3: Apply dependent static data (depends on the object's state from the previous step)
  runConditionals(frame, template, options)

  -- STEP 4: Apply the Create method to the base frame, from the oldest parent to this one
  runCreate(frame, template)

  -- FINALIZING: Flag the frame as created, flush any events that may have queued up
  frame._frameCreated = true
  frame:FlushEventQueue()

  -- FINALIZING: If autoRefresh is not explicitly disabled, run the frame's Refresh method now
  if frame._options.autoRefresh ~= false then
    frame:Refresh()
  end

  return frame
end

--------------------
-- PUBLIC METHODS --
--------------------

--- Registers a new type of UI frame for PMQ.
--- @param frameType string A unique type name for the frame
--- @param inheritsFrom string The type of frame that will be created as a basis for this frame (default: "Frame")
function addon:NewFrame(frameType, inheritsFrom, inheritsTemplate)
  local frameTemplate = newFrameTemplate(frameType, inheritsFrom, inheritsTemplate)

  -- Always return the template even if validation fails, so we don't get null refs during file load
  if type(frameTemplate._frameType) ~= "string" then
    addon.UILogger:Error("Failed to create NewFrame: frameType is required")
    return frameTemplate
  end
  if frameTemplates[frameTemplate._frameType] then
    addon.UILogger:Error("Failed to create NewFrame: frameType \"%s\" already exists", frameType)
    return frameTemplate
  end
  if frameTemplate._inhertsFrom ~= nil and type(frameTemplate._inheritsFrom) ~= "string" then
    addon.UILogger:Error("Failed to create NewFrame: inheritsFrom must be a string")
    return frameTemplate
  end

  -- But only register the template if validation was successful
  frameTemplates[frameType] = frameTemplate
  return frameTemplate
end

--- Registers a new type of Mixin for PMQ.
--- All regular frames can also be applied as mixins, but mixins cannot be
--- created as standalone frames (via addon:CreateFrame).
--- @param frameType string A unique type name for the mixin
function addon:NewMixin(frameType)
  local frameTemplate = newFrameTemplate(frameType)

  -- Always return the template even if validation fails, so we don't get null refs during file load
  if type(frameTemplate._frameType) ~= "string" then
    addon.UILogger:Error("Failed to create NewMixin: frameType is required")
    return frameTemplate
  end
  if frameTemplates[frameTemplate._frameType] then
    addon.UILogger:Error("Failed to create NewMixin: frameType \"%s\" already exists", frameType)
    return frameTemplate
  end

  -- But only register the template if validation was successful
  frameTemplate._mixinOnly = true -- This flag prevents it from being called during CreateFrame
  frameTemplates[frameType] = frameTemplate
  return frameTemplate
end

function addon:CreateFrame(frameType, frameName, parent, ...)
  asserttype(frameType, "string", "frameType", "CreateFrame", 2)
  asserttype(frameName or "", "string", "frameName", "CreateFrame", 2)

  -- Set the default parent if one was not provided
  if not parent then
    parent = UIParent
  else
    assertframe(parent, "parent", "CreateFrame", 2)
  end

  -- Generate a unique global name for this frame
  frameName = createFrameName(frameType, frameName, parent)

  local frameTemplate = frameTemplates[frameType]
  if not frameTemplate then
    -- If this is not a custom widget type, bypass the custom widget creation process
    -- and just return the created Blizzard frame
    return CreateFrame(frameType, frameName, parent, ...)
  else
    -- Otherwise, do all the custom widget creation stuff seen above
    assertf(not frameTemplate._mixinOnly, "Cannot CreateFrame from mixin '%s'", frameType)
    return createCustomFrame(frameType, frameName, parent, ...)
  end
end
