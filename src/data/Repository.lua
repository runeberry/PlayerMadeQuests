local _, addon = ...
addon:traceFile("Repository.lua")
local time = addon.G.time

addon.Data = {}
local logger = addon.Logger:NewLogger("Data", addon.LogLevel.info)
local repos = {}
local defaultPkey = "id"
local createDateKey = "cd"
local updateDateKey = "ud"
local transactionLogs = addon.TRANSACTION_LOGS or false

local function addItemToIndex(indexTable, item, indexProp)
  local indexValue = item[indexProp]
  if indexValue == nil then
    if indexTable.optional then
      return
    elseif indexTable.generator then
      indexValue = indexTable.generator(item)
      if indexValue == nil then
        error("Required index value "..indexProp.." could not be generated")
      end
      item[indexProp] = indexValue
    else
      error("Required index value "..indexProp.." is missing")
    end
  end

  if indexTable.unique then
    if indexTable.data[indexValue] then
      error("Index value is not unique for property "..indexProp.." = "..indexValue)
    end
    -- If index is 1:1, set the item for this index value here
    indexTable.data[indexValue] = item
  else
    -- If index is 1:many, create a new table (if needed) and add this
    -- item to this index value's table
    if not indexTable.data[indexValue] then
      indexTable.data[indexValue] = {}
    end
    indexTable.data[indexValue][item] = true
  end
end

local function removeItemFromIndex(indexTable, item, indexProp)
  local indexValue = item[indexProp]
  if indexValue == nil then return end

  if indexTable.unique then
    -- If index is 1:1, then just set this index value to nil
    indexTable.data[indexValue] = nil
  else
    -- If index is 1:many, then remove this item from the list
    indexTable.data[indexValue][item] = nil
    local isIndexEmpty = true
    for _, _ in pairs(indexTable.data[indexValue]) do
      isIndexEmpty = false
      break
    end
    if isIndexEmpty then
      -- If this was the last item at this index value, set this index value to nil
      indexTable.data[indexValue] = nil
    end
  end
end

local function indexItem(repo, item)
  for indexProp, indexTable in pairs(repo.index) do
    addItemToIndex(indexTable, item, indexProp)
  end
end

local function deindexItem(repo, item)
  for indexProp, indexTable in pairs(repo.index) do
    removeItemFromIndex(indexTable, item, indexProp)
  end
end

local function createIndexTable(data, indexProp, options)
  local indexTable = { data = {} }
  if options then
    indexTable.unique = options.unique
    indexTable.optional = options.optional
    indexTable.generator = options.generator
  end
  -- Index any existing data
  for item in pairs(data) do
    addItemToIndex(indexTable, item, indexProp)
  end
  return indexTable
end

-- Clears out existing indexes and rebuilds them all for the repo's data
local function indexAllData(repo)
  for indexProp, indexTable in pairs(repo.index) do
    indexTable.data = {}
    for item in pairs(repo.data) do
      addItemToIndex(indexTable, item, indexProp)
    end
  end
  -- repo.logger:Trace("Reindexed repository:", addon:tlen(repo.index), "index(es)")
end

local function deindexAllData(repo)
  for indexProp, indexTable in pairs(repo.index) do
    indexTable.data = {}
  end
end

local function readSaveData(repo)
  if not repo._saveDataField then return end

  if repo._compressionEnabled then
    local compressed = addon.SaveData:LoadString(repo._saveDataField, repo._useGlobalSaveData)
    local array = addon:DecompressTable(compressed)
    repo.data = addon:DistinctSet(array)
  else
    local array = addon.SaveData:LoadTable(repo._saveDataField, repo._useGlobalSaveData)
    repo.data = addon:DistinctSet(array)
  end
end

local function writeSaveData(repo)
  if not repo._saveDataField then return end

  if repo._compressionEnabled then
    local array = addon:SetToArray(repo.data)
    local compressed = addon:CompressTable(array)
    addon.SaveData:Save(repo._saveDataField, compressed, repo._useGlobalSaveData)
  else
    local array = addon:SetToArray(repo.data)
    addon.SaveData:Save(repo._saveDataField, array, repo._useGlobalSaveData)
  end
end

local function findEntitiesByIndex(repo, indexProp, indexValue)
  local indexTable = repo.index[indexProp]
  if not indexTable then return end
  local indexed, count, result = indexTable.data[indexValue]
  if indexTable.unique then
    if indexed == nil then
      result = nil
      count = 0
    else
      result = indexed
      count = 1
    end
  else
    if indexed == nil then
      result = {}
      count = 0
    else
      result = {}
      for item in pairs(indexed) do
        table.insert(result, item)
      end
      count = #result
    end
  end
  return result, count
end

local function ta_AddStep(self, action, undo)
  table.insert(self.steps, { action = action, undo = undo })
end

local function ta_Log(self, ...)
  if not transactionLogs then return end
  self.repo.logger:Debug(...)
end

local function ta_Run(self)
  local ok, err, failstep
  -- Run each step in the transaction, and break out if any step fails
  for i, t in ipairs(self.steps) do
    self:Log("Running transaction step:", i)
    ok, err = pcall(t.action)
    if not ok then
      self:Log("Failed step, beginning undo")
      failstep = i
      break
    end
  end
  -- If any transaction action failed, then run the corresponding undo action
  -- Undo actions are run in the reverse order in which their actions were run
  if not ok then
    local undoOk, undoErr
    for i = failstep, 1, -1 do
      local t = self.steps[i]
      if t.undo then
        self:Log("Undoing transaction step:", i)
        undoOk, undoErr = pcall(t.undo)
        if not undoOk then
          logger:Fatal("Transaction undo failed. Repository may be in a bad state!")
          logger:Fatal(undoErr)
          break
        end
      else
        self:Log("Undoing transaction step:", i, "(no-op)")
      end
    end
    -- Return the original transaction error for the repository to handle
    self:Log("Transaction rolled back")
    return ok, err
  end
  -- All transaction items executed without error
  self:Log("Transaction succeeded")
  return true
end

local function newTransaction(repo)
  return {
    repo = repo,
    steps = {},
    AddStep = ta_AddStep,
    Run = ta_Run,
    Log = ta_Log
  }
end

local methods = {
  ------------------
  -- Read Methods --
  ------------------
  ["FindAll"] = function(self)
    local results = {}
    if self._directReadEnabled then
      for item in pairs(self.data) do
        table.insert(results, item)
      end
    else
      for item in pairs(self.data) do
        table.insert(results, addon:CopyTable(item))
      end
    end
    self.logger:Trace("FindAll:", #results, "result(s)")
    return results
  end,
  ["FindByID"] = function(self, id)
    local result, count = findEntitiesByIndex(self, self.pkey, id)

    if not self._directReadEnabled and result then
      result = addon:CopyTable(result)
    end

    self.logger:Trace("FindByID =", id, ":", count, "result(s)")
    return result
  end,
  ["FindByIndex"] = function(self, indexProp, indexValue)
    if type(indexProp) ~= "string" then
      self.logger:Error("Failed to FindByIndex:", type(indexProp), "is not a valid property name")
      return nil
    end
    local indexTable = self.index[indexProp]
    if not indexTable then
      self.logger:Error("Failed to FindByIndex: no index exists for property", indexProp)
      return nil
    end

    local result, count = findEntitiesByIndex(self, indexProp, indexValue)

    -- To keep return values consistent, unique results will be returned as a
    -- table of results with just one item
    if indexTable.unique then
      result = { result }
    end

    if result then
      if not self._directReadEnabled then
        result = addon:CopyTable(result)
      end
    else
      -- Even if there's nothing at this index, return an empty table of results
      result = {}
    end

    self.logger:Trace("FindByIndex", indexProp, "=", indexValue, ":", count, "result(s)")
    return result
  end,
  ["FindByQuery"] = function(self, queryFunction)
    if type(queryFunction) ~= "function" then
      self.logger:Error("Failed to FindByQuery:", type(queryFunction) "is not a valid query function")
      return {}
    end
    local results = {}
    for item in pairs(self.data) do
      if queryFunction(item) then
        if not self._directReadEnabled then
          item = addon:CopyTable(item)
        end
        table.insert(results, item)
      end
    end
    self.logger:Trace("FindByQuery:", #results, "results")
    return results
  end,
  -------------------
  -- Write Methods --
  -------------------
  ["Save"] = function(self, entity)
    assert(entity ~= nil, "Failed to Save: Cannot save a nil entity")
    if not self._writeEnabled then
      self.logger:Error("Failed to Save: Repository is read-only")
      return
    end
    local transaction = newTransaction(self)
    if self._pkgenEnabled and not entity[self.pkey] then
      transaction:AddStep(function()
        entity[self.pkey] = self.index[self.pkey].generator(entity)
      end, function()
        entity[self.pkey] = nil
      end)
    end
    transaction:AddStep(function()
      assert(entity[self.pkey], "Primary key "..self.pkey.." is required")
      if self.Validate then
        self:Validate(entity)
      end
    end)
    local event, msg
    local existing = findEntitiesByIndex(self, self.pkey, entity[self.pkey])
    if existing then
      -- If an entity exists by this ID, then it's an update
      if existing == entity then
        -- If direct read is enabled, then the entity being saved will be
        -- the same entity in the data source, so it is already updated
        event, msg = self.events.EntityUpdated, "Entity updated (direct read)"
        transaction:AddStep(function()
          deindexItem(self, entity)
          indexItem(self, entity)
        end, function()
          -- I do not know how to recover if this happens
          error("Reindexing failed, unrecoverable error")
        end)
        if self._timestampsEnabled then
          local ts, origUpdateDate = time()
          transaction:AddStep(function()
            origUpdateDate = entity[updateDateKey]
            entity[updateDateKey] = ts
          end, function()
            entity[updateDateKey] = origUpdateDate
          end)
        end
      elseif self.data[existing] then
        event, msg = self.events.EntityUpdated, "Entity updated"
        local dsCopy
        transaction:AddStep(function()
          dsCopy = addon:CopyTable(entity)
        end)
        if self._timestampsEnabled then
          local ts, origUpdateDate = time()
          transaction:AddStep(function()
            origUpdateDate = dsCopy[updateDateKey]
            dsCopy[updateDateKey] = ts
          end, function()
            dsCopy[updateDateKey] = origUpdateDate
          end)
        end
        transaction:AddStep(function()
          deindexItem(self, existing)
        end, function()
          indexItem(self, existing)
        end)
        transaction:AddStep(function()
          indexItem(self, dsCopy)
        end, function()
          deindexItem(self, dsCopy)
        end)
        transaction:AddStep(function()
          self.data[existing] = nil
          self.data[dsCopy] = true
        end, function()
          self.data[existing] = true
          self.data[dsCopy] = nil
        end)
      else
        transaction:AddStep(function()
          error("No update path for entity:"..entity[self.pkey])
        end)
      end
    else
      -- If an entity does not exist by this ID, then it's an insert
      event, msg = self.events.EntityAdded, "Entity added"
      local insertable
      transaction:AddStep(function()
        insertable = entity
        if not self._directReadEnabled then
          insertable = addon:CopyTable(insertable)
        end
      end)
      if self._timestampsEnabled then
        local ts = time()
        transaction:AddStep(function()
          insertable[createDateKey] = ts
          insertable[updateDateKey] = ts
        end, function()
          insertable[createDateKey] = nil
          insertable[updateDateKey] = nil
        end)
      end
      transaction:AddStep(function()
        self.data[insertable] = true
      end, function()
        self.data[insertable] = nil
      end)
      transaction:AddStep(function()
        indexItem(self, insertable)
      end, function()
        deindexItem(self, insertable)
      end)
    end
    local ok, err = transaction:Run()
    if not ok then
      self.logger:Error("Failed to Save:", err)
      return
    end
    if event then
      self.logger:Trace(msg, ":", entity[self.pkey])
      addon.AppEvents:Publish(event, entity)
      writeSaveData(self)
    end
  end,
  ["Delete"] = function(self, idOrEntity)
    if not self._writeEnabled then
      self.logger:Error("Failed to Delete: Repository is read-only")
      return
    end
    local id = idOrEntity
    if type(id) == "table" then
      id = id[self.pkey]
    end
    if not id then
      self.logger:Error("Failed to Delete:", self.pkey, "is required")
      return
    end
    local existing = findEntitiesByIndex(self, self.pkey, id)
    if not existing then
      self.logger:Trace("Nothing to delete for id:", id)
      return
    end

    local transaction = newTransaction(self)
    transaction:AddStep(function()
      deindexItem(self, existing)
      self.data[existing] = nil
    end, function()
      self.data[existing] = true
      indexItem(self, existing)
    end)

    local ok, err = transaction:Run()
    if not ok then
      self.logger:Error("Failed to Delete:", err)
      return
    end

    self.logger:Trace("Entity deleted:", id)
    writeSaveData(self)
    addon.AppEvents:Publish(self.events.EntityDeleted, existing)
  end,
  --------------------
  -- Config Methods --
  --------------------
  ["AddIndex"] = function(self, indexProp, options)
    if self.index[indexProp] then
      self.logger:Warn("Index already exists for property:", indexProp)
      return
    end
    local result, indexTable = pcall(createIndexTable, self.data, indexProp, options)
    if not result then
      self.logger:Error("Failed to AddIndex:", indexTable)
      return
    end
    self.logger:Trace("Added index on property", indexProp)
    self.index[indexProp] = indexTable
  end,
  ["SetSaveDataSource"] = function(self, saveDataField)
    if self._hasDataSource then
      self.logger:Error("Failed to SetSaveDataSource: a data source is already set")
      return
    end
    addon:OnSaveDataLoaded(function()
      local transaction = newTransaction(self)
      transaction:AddStep(function()
        self._saveDataField = saveDataField
        readSaveData(self)
      end, function()
        self._saveDataField = nil
      end)
      transaction:AddStep(function()
        indexAllData(self)
      end, function()
        deindexAllData(self)
      end)
      local ok, err = transaction:Run()
      if not ok then
        self.logger:Error("Failed to SetSaveDataSource:", err)
        return
      end
      self._hasDataSource = true
      -- self.logger:Trace("SetSaveDataSource to", saveDataField, ":", addon:tlen(self.data), "item(s)")
      addon.AppEvents:Publish(self.events.EntityDataLoaded, self)
    end)
  end,
  ["SetTableSource"] = function(self, dataSource)
    if self._hasDataSource then
      self.logger:Error("Failed to SetTableSource: a data source is already set")
      return
    end
    if type(dataSource) ~= "table" then
      self.logger:Error("Failed to SetTableSource: expected table, got", type(dataSource))
      return
    end
    local transaction = newTransaction(self)
    local set, count
    transaction:AddStep(function()
      set, count = addon:DistinctSet(dataSource)
      self.data = set
    end, function()
      self.data = {}
    end)
    transaction:AddStep(function()
      indexAllData(self)
    end, function()
      deindexAllData(self)
    end)
    local ok, err = transaction:Run()
    if not ok then
      self.logger:Error("Failed to SetTableSource:", err)
      return
    end
    self._hasDataSource = true
    -- self.logger:Trace("SetTableSource:", count, "item(s)")
    addon.AppEvents:Publish(self.events.EntityDataLoaded, self)
  end,
  ["EnableCompression"] = function(self, flag)
    if flag and self._directReadEnabled then
      self.logger:Error("Cannot EnableCompression: this option is incompatible with EnableDirectRead")
      return
    end
    self._compressionEnabled = flag
  end,
  ["EnableDirectRead"] = function(self, flag)
    if flag and self._compressionEnabled then
      self.logger:Error("Cannot EnableDirectRead: this option is incompatible with EnableCompression")
      return
    end
    self._directReadEnabled = flag
  end,
  ["EnableGlobalSaveData"] = function(self, flag)
    self._useGlobalSaveData = flag
  end,
  ["EnablePrimaryKeyGeneration"] = function(self, flag)
    self._pkgenEnabled = flag
  end,
  ["EnableTimestamps"] = function(self, flag)
    self._timestampsEnabled = flag
  end,
  ["EnableWrite"] = function(self, flag)
    self._writeEnabled = flag
  end,
}

------------------
-- Constructors --
------------------

function addon.Data:NewRepository(name, pkey)
  local repo = {
    name = name,
    pkey = pkey or defaultPkey,
    data = {},
    index = {},
    logger = logger:NewLogger(name),
    events = {
      EntityAdded = name.."Added",
      EntityUpdated = name.."Updated",
      EntityDeleted = name.."Deleted",
      EntityDataLoaded = name.."DataLoaded"
    }
  }

  for methodName, func in pairs(methods) do
    repo[methodName] = func
  end

  repo:AddIndex(repo.pkey, {
    unique = true,
    generator = function()
      if repo._pkgenEnabled then
        return addon:CreateID(repo.name.."-%i")
      end
    end
  })

  repos[name] = repo
  logger:Trace("NewRepository:", name)
  return repo
end
