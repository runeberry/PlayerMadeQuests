local _, addon = ...
addon:traceFile("Repository.lua")

addon.Data = {}

local logger = addon.Logger:NewLogger("Data")

local datasources = {}
local databases = {}
local repos = {}

local function addItemToIndex(indexTable, item, indexProp)
  local indexValue = item[indexProp]
  if indexValue == nil then return end

  if indexTable.unique then
    if indexTable.data[indexValue] then
      error("Index value is not unique for property "..indexProp.." = "..indexValue)
    end
    indexTable.data[indexValue] = item
  else
    if not indexTable.data[indexValue] then
      indexTable.data[indexValue] = {}
    end
    table.insert(indexTable.data[indexValue], item)
  end
end

local function removeItemFromIndex(indexTable, item, indexProp)
  local indexValue = item[indexProp]
  if indexValue == nil then return end

  if indexTable.unique then

  else

  end
end

local function createIndexTable(data, indexProp, uniqueFlag)
  local indexTable = { unique = uniqueFlag, data = {} }
  -- Index any existing data
  for _, item in ipairs(data) do
    addItemToIndex(indexTable, item, indexProp)
  end
  return indexTable
end

-- Clears out existing indexes and rebuilds them all for the repo's data
local function indexAllData(repo)
  for indexProp, indexTable in pairs(repo.index) do
    local result, newTable = pcall(createIndexTable, repo.data, indexProp, indexTable.unique)
    if not result then
      repo.logger:Error("Failed to index data on property"..indexProp..":", newTable)
      repo.index[indexProp] = { unique = indexTable.unique, data = {} }
    else
      repo.index[indexProp] = newTable
    end
  end
  repo.logger:Trace("Reindexed repository:", addon:tlen(repo.index), "index(es)")
end

local methods = {
  ------------------
  -- Read Methods --
  ------------------
  ["FindAll"] = function(self)
    self.logger:Trace("FindAll:", #(self.data), "results")
    if self._directReadEnabled then
      return self.data
    else
      return addon:CopyTable(self.data)
    end
  end,
  ["FindByIndex"] = function(self, indexProp, indexValue)
    if type(indexProp) ~= "string" then
      self.logger:Error("Failed to FindByIndex:", type(indexProp), "is not a valid property name")
      return nil
    end
    if not self.index[indexProp] then
      self.logger:Error("Failed to FindByIndex: no index exists for property", indexProp)
      return nil
    end
    -- Return an empty table if no results are indexed by this value
    local results = self.index[indexProp].data[indexValue] or {}
    self.logger:Trace("FindByIndex", indexProp, "=", indexValue, ":", #results, "results")
    if self._directReadEnabled then
      return results
    else
      return addon:CopyTable(results)
    end
  end,
  ["FindByQuery"] = function(self, queryFunction)
    if type(queryFunction) ~= "function" then
      self.logger:Error("Failed to FindByQuery:", type(queryFunction) "is not a valid query function")
      return {}
    end
    local results = {}
    for _, item in ipairs(self.data) do
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
  ["Insert"] = function(self, entity)
    if not self._writeEnabled then
      self.logger:Error("Failed to Insert: repository is read-only")
      return
    end
    self.logger:Warn("Insert method not implemented!")
  end,
  ["Delete"] = function(self, id)
    if not self._writeEnabled then
      self.logger:Error("Failed to Insert: repository is read-only")
      return
    end
    self.logger:Warn("Delete method not implemented!")
  end,
  --------------------
  -- Config Methods --
  --------------------
  ["AddIndex"] = function(self, indexProp, uniqueFlag)
    if self.index[indexProp] then
      self.logger:Warn("Index already exists for property:", indexProp)
      return
    end
    local result, indexTable = pcall(createIndexTable, self.data, indexProp, uniqueFlag)
    if not result then
      self.logger:Error("Failed to AddIndex:", indexTable)
      return
    end
    self.logger:Trace("Added index on property", indexProp)
    self.index[indexProp] = indexTable
  end,
  ["SetDataSource"] = function(self, dataSource)
    if type(dataSource) == "table" then
      self.data = dataSource
      self.logger:Trace("SetDataSource to table:", #(self.data), "items")
      indexAllData(self)
    elseif type(dataSource) == "string" then
      addon:OnSaveDataLoaded(function()
        local ds = datasources[dataSource]
        if not ds then
          self.logger:Error("Failed to SetDataSource: no dataset exists at source", dataSource)
        elseif type(ds.data) ~= "table" then
          self.logger:Error("Failed to SetDataSource", dataSource, ": expected table, got", type(ds.data))
        else
          self.data = ds.data
          self.logger:Trace("SetDataSource to", dataSource, ":", #(self.data), "items")
          indexAllData(self)
        end
      end)
    elseif type(dataSource) == "function" then
      addon:OnSaveDataLoaded(function()
        local result, ds = pcall(dataSource)
        if not result then
          self.logger:Error("Failed to AddDataSource:", ds)
        elseif type(ds) ~= "table" then
          self.logger:Error("Failed to AddDataSource: expected table, got", type(ds))
        else
          self.data = ds
          self.logger:Trace("SetDataSource to function:", #(self.data), "items")
          indexAllData(self)
        end
      end)
    else
      self.logger:Error("Failed to AddDataSource: expected table or function, got", type(dataSource))
    end
  end,
  ["EnableCompression"] = function(self, flag)
    self._compressionEnabled = flag
  end,
  ["EnableDirectRead"] = function(self, flag)
    self._directReadEnabled = flag
  end,
  ["EnableWrite"] = function(self, flag)
    self._writeEnabled = flag
  end
}

------------------
-- Constructors --
------------------

function addon.Data:NewDataSource(name, data)
  local source = {
    name = name,
    data = data
  }

  datasources[name] = source
  logger:Trace("NewDataSource:", name, "(", addon:tlen(data), "items )")
  return source
end

function addon.Data:NewRepository(name)
  local repo = {
    name = name,
    data = {},
    index = {},
    logger = logger:NewLogger(name)
  }

  for methodName, func in pairs(methods) do
    repo[methodName] = func
  end

  repos[name] = repo
  logger:Trace("NewRepository:", name)
  return repo
end
