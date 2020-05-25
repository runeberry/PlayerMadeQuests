local builder = require("spec/addon-builder")
local addon = builder:Build()
local testLogger = addon.Logger:NewLogger("UnitTest", "debug")

local counter = 0
local function createTestEntity()
  counter = counter + 1
  return {
    name = addon:CreateID("entity-name-%i"),
    value = counter
  }
end

local function createTestEntities(count)
  local entities = {}
  for i = 1, count, 1 do
    table.insert(entities, createTestEntity())
  end
  return entities
end

describe("Repository", function()
  local repo

  setup(function()
    addon:Init()
    addon:Advance()
  end)
  before_each(function()
    repo = addon.Data:NewRepository("Test")
  end)
  describe("FindAll", function()
    it("can return all entities", function()
      local testData = createTestEntities(3)
      repo:EnablePrimaryKeyGeneration(true)
      repo:SetTableSource(testData)

      local results = repo:FindAll()
      -- Order is not guaranteed by FindAll, so sort it for the assertion
      local sort = function(e1, e2) return e1.name < e2.name end
      table.sort(testData, sort)
      table.sort(results, sort)

      assert.same(testData, results)
    end)
    it("can return an empty table if there is no data", function()
      local results = repo:FindAll()
      assert.equals(0, #results)
    end)
  end)
  describe("FindByID", function()
    it("can return an entity by its primary key", function()
      local testData = createTestEntities(3)
      repo:EnablePrimaryKeyGeneration(true)
      repo:SetTableSource(testData)
      local expected = testData[2]

      local result = repo:FindByID(expected.id)

      assert.same(expected, result)
    end)
    it("can return nil if no entity has that primary key", function()
      local testData = createTestEntities(3)
      repo:EnablePrimaryKeyGeneration(true)
      repo:SetTableSource(testData)

      assert.is_nil(repo:FindByID("fake id"))
    end)
    it("can return nil if there is no data", function()
      assert.is_nil(repo:FindByID("fake id"))
    end)
  end)
  describe("FindByQuery", function()
    local testData
    before_each(function()
      testData = createTestEntities(3)
    end)
    it("can find records by a query function", function()
      repo:EnablePrimaryKeyGeneration(true)
      repo:SetTableSource(testData)

      local query = function(e) return e.value > testData[1].value end
      local results = repo:FindByQuery(query)
      assert.equals(2, #results)
    end)
  end)
  describe("Save", function()
    before_each(function()
      repo:EnableWrite(true)
    end)
    it("cannot save a record without a primary key", function()
      local entity = createTestEntity()
      assert.is_nil(entity.id)

      repo.logger:SetLogLevel("silent") -- hide intentional error
      repo:Save(entity)
      local results = repo:FindAll()

      assert.equals(0, #results)
    end)
    it("can generate PK for a record without a PK, if enabled", function()
      repo:EnablePrimaryKeyGeneration(true)
      local entity = createTestEntity()
      assert.is_nil(entity.id)

      repo:Save(entity)
      assert.is_not_nil(entity.id)

      local result = repo:FindByID(entity.id)
      assert.same(entity, result)
    end)
    it("can overwrite a record with an existing primary key", function()
      local testData = createTestEntities(2)
      local testId = "test-id"
      testData[1].id = testId
      testData[2].id = testId
      assert.not_same(testData[1], testData[2])

      repo:Save(testData[1])
      local result = repo:FindByID(testId)
      assert.same(testData[1], result)

      repo:Save(testData[2])
      result = repo:FindByID(testId)
      assert.same(testData[2], result)
    end)
    it("can save a new record if the primary key is changed", function()
      local entity = createTestEntity()
      entity.id = "test-id"

      repo:Save(entity)
      entity.id = "different-id"
      repo:Save(entity)

      local result = repo:FindByID(entity.id)
      assert.same(entity, result)

      result = repo:FindByID("test-id")
      assert.not_nil(result)
      assert.equals(entity.name, result.name)
    end)
    it("cannot save a record that violates a unique index", function()
      local testData = createTestEntities(2)
      testData[2].value = testData[1].value
      repo:EnablePrimaryKeyGeneration(true)
      repo:AddIndex("value", { unique = true })

      repo:Save(testData[1])
      local result = repo:FindByID(testData[1].id)
      assert.not_nil(result)

      repo.logger:SetLogLevel("silent") -- Hide intentional error
      repo:Save(testData[2])
      result = repo:FindByID(testData[2].id)
      assert.is_nil(result)

      local results = repo:FindAll()
      assert.equals(1, #results)
    end)
  end)
  describe("Delete", function()
    local testData
    before_each(function()
      testData = createTestEntities(3)
      repo:EnableWrite(true)
      repo:EnablePrimaryKeyGeneration(true)
      repo:SetTableSource(testData)
    end)
    it("can delete a record by primary key", function()
      local toDelete = testData[1]
      repo:Delete(toDelete.id)

      local results = repo:FindAll()
      assert.equals(2, #results)

      local result = repo:FindByID(toDelete.id)
      assert.is_nil(result)
    end)
    it("can delete a record by entity", function()
      local toDelete = testData[1]
      repo:Delete(toDelete)

      local results = repo:FindAll()
      assert.equals(2, #results)

      local result = repo:FindByID(toDelete.id)
      assert.is_nil(result)
    end)
    it("cannot delete a record by entity without a primary key", function()
      local toDelete = testData[1]
      toDelete.id = nil
      repo.logger:SetLogLevel("silent") -- Hide intentional error
      repo:Delete(toDelete)

      local results = repo:FindAll()
      assert.equals(3, #results)
    end)
  end)
  describe("Indexing", function()
    it("can create a non-unique index", function()
      repo:AddIndex("name")
      local testData = createTestEntities(3)
      repo:EnablePrimaryKeyGeneration(true)
      repo:SetTableSource(testData)
      local expected = testData[1]

      local results = repo:FindByIndex("name", expected.name)

      assert.equals(1, #results)
      assert.same(expected, results[1])
    end)
    it("can create a unique index", function()
      repo:AddIndex("value", { unique = true })
      local testData = createTestEntities(3)
      repo:EnablePrimaryKeyGeneration(true)
      repo:SetTableSource(testData)
      local expected = testData[2]

      local results = repo:FindByIndex("value", expected.value)

      assert.equals(1, #results)
      assert.same(expected, results[1])
    end)
    it("can create an index after table source is set", function()
      local testData = createTestEntities(3)
      repo:EnablePrimaryKeyGeneration(true)
      repo:SetTableSource(testData)
      repo:AddIndex("name")
      local expected = testData[3]

      local results = repo:FindByIndex("name", expected.name)

      assert.equals(1, #results)
      assert.same(expected, results[1])
    end)
  end)
  describe("SetSaveDataSource", function()
    local saveDataField, testData, tempAddon
    before_each(function()
      -- Save data is stored in a global field, so to use fresh save data
      -- we need to specify a different field for every test
      saveDataField = addon:CreateID("save-data-%i")
      testData = createTestEntities(3)
      tempAddon = builder:Build()
      tempAddon:Init()
      repo = tempAddon.Data:NewRepository("SaveDataTest")
      repo:EnablePrimaryKeyGeneration(true)
      repo:EnableWrite(true)
    end)
    it("can set a save data source before load", function()
      tempAddon.SaveData:Save(saveDataField, testData)
      repo:SetSaveDataSource(saveDataField)
      tempAddon:Advance()

      local results = repo:FindAll()
      local sort = function(a,b) return a.id < b.id end
      table.sort(testData, sort)
      table.sort(results, sort)
      assert.same(testData, results)

      local sd = tempAddon.SaveData:LoadTable(saveDataField)
      table.sort(sd, sort)
      assert.same(testData, sd)
    end)
    it("can set a save data source after load", function()
      tempAddon:Advance()
      tempAddon.SaveData:Save(saveDataField, testData)
      repo:SetSaveDataSource(saveDataField)

      local results = repo:FindAll()
      local sort = function(a,b) return a.id < b.id end
      table.sort(testData, sort)
      table.sort(results, sort)
      assert.same(testData, results)

      local sd = tempAddon.SaveData:LoadTable(saveDataField)
      table.sort(sd, sort)
      assert.same(testData, sd)
    end)
    it("can save data to a new source", function()
      tempAddon:Advance()
      repo:SetSaveDataSource(saveDataField)

      local results = repo:FindAll()
      assert.equals(0, #results)

      local entity = testData[1]
      repo:Save(entity)
      results = repo:FindAll()
      assert.equals(1, #results)
      assert.same(entity, results[1])

      local result = repo:FindByID(entity.id)
      assert.same(entity, result)

      results = tempAddon.SaveData:LoadTable(saveDataField)
      assert.equals(1, #results)
      assert.same(entity, results[1])
    end)
    it("can save compressed data", function()
      repo:EnableCompression(true)
      tempAddon:Advance()
      repo:SetSaveDataSource(saveDataField)

      local results = repo:FindAll()
      assert.equals(0, #results)

      local entity = testData[1]
      repo:Save(entity)
      results = repo:FindAll()
      assert.equals(1, #results)
      assert.same(entity, results[1])

      local result = repo:FindByID(entity.id)
      assert.same(entity, result)

      result = tempAddon.SaveData:LoadString(saveDataField)
      assert.is_string(result)

      local decompressed = tempAddon:DecompressTable(result)
      results = tempAddon:SetToArray(decompressed)
      assert.equals(1, #results)
      assert.same(entity, results[1])
    end)
    it("can load compressed data", function()
      repo:EnableCompression(true)
      -- Repo expects loaded data to already be a "distinct set"
      local compressed = tempAddon:CompressTable(addon:DistinctSet(testData))
      tempAddon.SaveData:Save(saveDataField, compressed)
      repo:SetSaveDataSource(saveDataField)
      tempAddon:Advance()

      local results = repo:FindAll()
      assert.equals(3, #results)

      local result = repo:FindByID(testData[1].id)
      assert.same(testData[1], result)
    end)
  end)
  describe("SetTableSource", function()
    local testData
    before_each(function()
      testData = createTestEntities(3)
    end)
    it("can set a data source from a table", function()
      for _, v in pairs(testData) do
        v.id = addon:CreateID("testData-%i")
      end
      repo:SetTableSource(testData)

      local results = repo:FindAll()
      local sort = function(a,b) return a.id < b.id end
      table.sort(testData, sort)
      table.sort(results, sort)
      assert.same(testData, results)
    end)
    it("cannot set a table source without primary keys", function()
      repo.logger:SetLogLevel("silent") -- Hide intentional error
      repo:SetTableSource(testData)

      local results = repo:FindAll()
      assert.equals(0, #results)
    end)
    it("can generate primary keys for a table source, if enabled", function()
      repo:EnablePrimaryKeyGeneration(true)
      repo:SetTableSource(testData)

      local results = repo:FindAll()
      local sort = function(a,b) return a.id < b.id end
      table.sort(testData, sort)
      table.sort(results, sort)
      assert.same(testData, results)
    end)
    it("cannot set a table source that violates a unique index", function()
      repo:EnablePrimaryKeyGeneration(true)
      repo:AddIndex("value", { unique = true })
      testData[2].value = testData[1].value
      repo.logger:SetLogLevel("silent") -- Hide intentional error
      repo:SetTableSource(testData)

      local results = repo:FindAll()
      assert.equals(0, #results)
    end)
  end)
end)