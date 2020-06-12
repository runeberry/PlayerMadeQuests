local _, addon = ...

local logger = addon.Logger:NewLogger("Compiler", addon.LogLevel.info)

addon.QuestScriptCompiler = {}

local commands = {}
local objectives = {}
local scripts = {}
local cleanNamePattern = "^[%l%d]+$"

local function getPositionalArgValue(args, position)
  local val = args.ordered[position]
  if val then
    return val.value
  end
end

local function getNamedArgValues(args, name)
  local val = args.named[name]
  if val then
    local arr = {}
    for i, v in ipairs(val) do
      arr[i] = v.value
    end
    return arr
  end
end

local function getAliases(param)
  -- A param's name is always its primary alias
  local aliases = { param.name }
  if type(param.alias) == "string" then
    -- Single alias
    table.insert(aliases, param.alias)
  elseif type(param.alias) == "table" then
    -- Multiple aliases
    for _, a in ipairs(param.alias) do
      table.insert(aliases, a)
    end
  end
  if param.position then
    table.insert(aliases, param.position)
  end
  return aliases
end

--[[
  Returns the string value of the requested arg
  If multiple keys are specified, the first one found will be returned
  If multiple values were set, returns the last value specified
  If no value was set, returns nil
--]]
local function args_GetValue(args, token)
  local aliases = getAliases(args._parent._paramsByName[token])
  local val
  for _, alias in pairs(aliases) do
    if type(alias) == "number" then
      val = getPositionalArgValue(args, alias)
      if val then return val end
    else
      val = getNamedArgValues(args, alias)
      -- In case multiple values were specified, return the last one only
      if val then return val[#val] end
    end
  end
end

--[[
  Returns all string values specified for this arg in the order that they were set
  If multiple keys are specified, the values for all will be returned
  If a single value was set, it's returned as a table with one element
  If no value was set, returns nil
--]]
local function args_GetValues(args, token)
  local aliases = getAliases(args._parent._paramsByName[token])
  local ret, val
  for _, alias in pairs(aliases) do
    if type(alias) == "number" then
      val = getPositionalArgValue(args, alias)
      if val then
        -- Positional arg values takes the lowest priority, after any named aliases
        -- If there is already one or more named values, do not add positionals
        if not ret then
          -- If you've gotten to this point, just return the single positional value
          return { val }
        end
      end
    else
      val = getNamedArgValues(args, alias)
      if val then
        ret = ret or {}
        for _, v in ipairs(val) do
          table.insert(ret, v)
        end
      end
    end
  end
  return ret
end

local Q_start_ptn, Q_end_ptn = [=[^(['"])]=], [=[(['"])$]=]
local SQ_start_ptn, DQ_start_ptn, SQ_end_ptn, DQ_end_ptn = [[^(')]], [[^(")]], [[(')$]], [[(")$]]
local escSQ_end_ptn, escDQ_end_ptn = [[(\)(')]], [[(\)(")]]
local esc_ptn = [=[(\*)['"]$]=]

-- Parser tries to convert values to each of the following types, in the order listed
-- If the coercer retruns nil, parser will try to convert to the next type in the chain
local coercers = {
  function(str) -- quoted string
    -- Remove the quotes from either side of the raw string
    local dequoted = str:gsub(Q_start_ptn, ""):gsub(Q_end_ptn, "")
    -- If this made any difference in the raw string, then the value was quoted and must be a string
    if dequoted ~= str then
      -- Since it was quoted, remove escape characters from these inner characters: ["'=]
      return dequoted:gsub([=[(\)(["'=])]=], "%2")
    end
  end,
  function(str) -- number
    return tonumber(str)
  end,
  function(str) -- boolean
    str = str:lower()
    if str == "true" then
      return true
    elseif str == "false" then
      return false
    end
  end,
  function(str) -- unquoted string
    return str
  end
}

local function parseArgs(line)
  -- Normalize spacing around named arguments
  line = line:gsub([=[([^\])%s*=%s*(%S)]=], "%1= %2")

  -- Split parts on space, but keep quoted groups together
  -- Solution adapted from: https://stackoverflow.com/a/28664691
  local args = {
    ordered = {},
    named = {}
  }

  local buf, quoted, pname
  for str in line:gmatch("%S+") do
    local SQ_start = str:match(SQ_start_ptn)
    local SQ_end = str:match(SQ_end_ptn)
    local DQ_start = str:match(DQ_start_ptn)
    local DQ_end = str:match(DQ_end_ptn)
    local escSQ_end = str:match(escSQ_end_ptn)
    local escDQ_end = str:match(escDQ_end_ptn)
    local escaped = str:match(esc_ptn)
    if not quoted and SQ_start and (not SQ_end or escSQ_end) then
      buf, quoted = str, SQ_start
    elseif not quoted and DQ_start and (not DQ_end or escDQ_end) then
      buf, quoted = str, DQ_start
    elseif buf and (SQ_end == quoted or DQ_end == quoted) and #escaped % 2 == 0 then
      str, buf, quoted = buf .. ' ' .. str, nil, nil
    elseif buf then
      buf = buf .. ' ' .. str
    end
    if not buf then
      --[[
        Create an object to store all relevant information about the parameter
        pvalue model: {
          raw = "string",   -- The literal value input, quotes and all
          value = any,      -- The type-coerced value, as determined by the coercers
          type = "string",  -- The type of the value
          key = "string"    -- The original pname or position that this value came from
        }
      --]]
      local pvalue = { raw = str }

      -- Attempt each type coercion until a successful result is found
      for _, coercer in ipairs(coercers) do
        pvalue.value = coercer(str)
        if pvalue.value then
          pvalue.type = type(pvalue.value)
          break
        end
      end

      if pname then
        -- If the last arg was a param name, then this is its value
        pvalue.key = pname
        local namedValues = args.named[pname]
        if not namedValues then
          namedValues = {}
          args.named[pname] = namedValues
        end
        table.insert(namedValues, pvalue)
        pname = nil
      else
        local pn = pvalue.raw:match("^(%w-)=$")
        if pn then
          -- This is the param name, next str will be the value
          pname = pn
        else
          -- This an ordered (unnamed) value
          if not args._parentName then
            -- The first unordered arg is always the command name, so
            -- it does not go into the ordered list
            args._parentName = pvalue
            pvalue.key = 0
          else
            table.insert(args.ordered, pvalue)
            pvalue.key = #args.ordered
          end
        end
      end
    end
  end
  if buf then error("Missing matching quote for: "..buf) end

  return args
end

local function getCommand(args)
  local commandName = args._parentName.value
  if not commandName then
    error("No command name specified")
  end
  local command = commands[commandName]
  if not command then
    error("No command exists with name: "..commandName)
  end
  if not command.scripts or not command.scripts.Parse then
    error("No Parse script is defined for command: "..commandName)
  end
  return command
end

local function processLine(line, parameters)
  local args = parseArgs(line)
  local command = getCommand(args)

  args._parent = command
  args.GetValue = args_GetValue
  args.GetValues = args_GetValues

  command.scripts.Parse(parameters, args)
end

local function initQuestScript(qsconfig)
  local function validateAndRegister(set, name, param)
    if not name or name == "" then
      error("Name/alias cannot be nil or empty")
    end
    if type(name) ~= "string" or not name:match(cleanNamePattern) then
      error("Name/alias must only contain lowercase alphanumeric characters")
    end
    if set[name] and set[name] ~= param then
      error("An item is already registered with name/alias: "..name)
    end
    set[name] = param
  end

  local function setup(set, param)
    local name = param.name
    -- An param's primary alias is its name
    validateAndRegister(set, name, param)

    local alias = param.alias
    if alias then
      if type(alias) == "string" then
        -- Single alias
        validateAndRegister(set, alias, param)
      elseif type(alias) == "table" then
        -- Multiple aliases
        for _, al in ipairs(alias) do
          validateAndRegister(set, al, param)
        end
      else
        error("Unrecognized alias type ("..type(alias)..") for:"..name)
      end
    end
    param._aliases = getAliases(param)

    local itemScripts = param.scripts
    if itemScripts then
      -- Replace the array of script names with a table like: { name = function }
      local newScripts = {}
      for _, methodName in pairs(itemScripts) do
        local method = scripts[name]
        if not method then
          error("No scripts registered for: "..name)
        end
        method = method[methodName]
        if not method then
          error("No script registered for "..name.." with name: "..methodName)
        end
        if type(method) ~= "function" then
          error("Non-function registered as script for "..name..": "..methodName)
        end
        newScripts[methodName] = method
      end
      param.scripts = newScripts
    end

    local params = param.params
    if params then
      local nameIndexed, positionIndexed = {}, {}

      for _, p in ipairs(params) do
        -- Recursively set up parameters exactly like their parent items
        setup(nameIndexed, p)
        if p.position then
          if positionIndexed[p.position] then
            error("Multiple parameters specified for position "..p.position.." on "..name)
          end
          positionIndexed[p.position] = p
        end
      end
      param._paramsByPosition = positionIndexed
      param._paramsByName = nameIndexed
    end
  end

  for _, command in ipairs(qsconfig.commands) do
    setup(commands, command)
  end
  for _, objective in ipairs(qsconfig.objectives) do
    setup(objectives, objective)
  end
end

--------------------
-- Public Methods --
--------------------

--[[
  Registers an arbitrary script by the specified unique name.
  Reference this script name in QuestScript.lua and it will be attached
  to the associated item and executed at the appropriate point in the quest lifecycle.
--]]
function addon.QuestScriptCompiler:AddScript(itemName, methodName, fn)
  if not itemName or itemName == "" then
    logger:Error("AddScript: itemName is required")
    logger:Debug("methodName:", methodName)
    return
  end
  if not methodName or methodName == "" then
    logger:Error("AddScript: methodName is required")
    logger:Debug("itemName:", itemName)
    return
  end

  local existing = scripts[itemName]
  if not existing then
    existing = {}
    scripts[itemName] = existing
  end

  if existing[methodName] then
    addon.Logger:Error("AddScript: script is already registered for", itemName, "with name", methodName)
    return
  end

  existing[methodName] = fn
end

function addon.QuestScriptCompiler:GetCommandInfo(cmdToken, paramToken)
  local command = commands[cmdToken]
  if not paramToken then return command end
  return command._paramsByName[paramToken]
end

function addon.QuestScriptCompiler:GetObjectiveInfo(objToken, paramToken)
  local obj = objectives[objToken]
  if not paramToken then return obj end
  return obj._paramsByName[paramToken]
end

--[[
  Parses a QuestScript "file" (set of lines) into an unvalidated quest object.
  The returned object takes on the following format:
  {
    name = "string",
    description = "string",
    objectives = {
      {
        name = "string",
        displayText = "string",
        goal = 1,
        conditions = {
          emote = { "val1": true },
          target = { "val2": true, "val3": true }
        }
      }
    }
  }
--]]
local newline_ptn, empty_ptn, comment_ptn = "[^\r\n]+", "^%s*$", "^#"
function addon.QuestScriptCompiler:Compile(script, params)
  local parameters
  if params then
    parameters = addon:CopyTable(params)
  else
    parameters = {}
  end
  if script ~= nil and script ~= "" then
    local lnum, ok, err = 0
    for line in script:gmatch(newline_ptn) do
      lnum = lnum + 1
      if line:match(comment_ptn) or line:match(empty_ptn) then
        -- Ignore comments and empty lines
      else
        ok, err = pcall(processLine, line, parameters)
        if not ok then
          error("Error on line "..lnum..": "..err)
        end
      end
    end
  end
  logger:Trace("Quest compiled")
  -- logger:Table(quest)
  return parameters
end

addon:onload(function()
  initQuestScript(addon.QuestScript)
  logger:Debug("QuestScript loaded OK!")
  addon.AppEvents:Publish("CompilerLoaded", objectives)
end)