local builder = require("spec/addon-builder")
local events = require("spec/events")
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
  local repo, eventSpy

  setup(function()
    addon:Init()
    addon:Advance()
    eventSpy = events:SpyOnEvents(addon.AppEvents)
  end)
  before_each(function()
    repo = addon:NewRepository("Test")
    eventSpy:Reset()
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
    describe("New Entity", function()
      it("can use the record's primary key, if already defined", function()
        local entity = createTestEntity()
        local testId = "just-a-test-identifier-of-some-sort"
        entity.id = testId

        repo:Save(entity)
        assert.equals(testId, entity.id)

        local result = repo:FindByID(testId)
        assert.same(entity, result)
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
      it("fires an EntityAdded event", function()
        repo:EnablePrimaryKeyGeneration(true)
        local entity = createTestEntity()
        repo:Save(entity)

        addon:Advance()
        local payload = eventSpy:GetPublishPayload(repo.events.EntityAdded)
        assert.same(entity, payload)
      end)
    end)
    describe("Existing Entity", function()
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
      it("fires an EntityUpdated event", function()
        repo:EnablePrimaryKeyGeneration(true)
        local entity = createTestEntity()
        repo:Save(entity)
        entity.name = entity.name.."updated"
        repo:Save(entity)

        addon:Advance()
        local payload = eventSpy:GetPublishPayload(repo.events.EntityUpdated)
        assert.same(entity, payload)
      end)
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
      local toDelete = testData[2]
      repo:Delete(toDelete)

      local results = repo:FindAll()
      assert.equals(2, #results)

      local result = repo:FindByID(toDelete.id)
      assert.is_nil(result)
    end)
    it("cannot delete a record by entity without a primary key", function()
      local toDelete = testData[3]
      toDelete.id = nil
      repo.logger:SetLogLevel("silent") -- Hide intentional error
      repo:Delete(toDelete)

      local results = repo:FindAll()
      assert.equals(3, #results)
    end)
    it("fires an EntityDeleted event", function()
      local toDelete = testData[3]
      repo:Delete(toDelete)

      addon:Advance()
      local payload = eventSpy:GetPublishPayload(repo.events.EntityDeleted)
      assert.same(toDelete, payload)
    end)
  end)
  describe("DeleteAll", function()
    local testData
    before_each(function()
      testData = createTestEntities(3)
      repo:EnableWrite(true)
      repo:EnablePrimaryKeyGeneration(true)
      repo:SetTableSource(testData)
    end)
    it("can delete all records", function()
      repo:DeleteAll()

      local results = repo:FindAll()
      assert.same({}, results)

      local result = repo:FindByID(testData[1].id)
      assert.is_nil(result)
    end)
    it("maintains index after delete", function()
      repo:DeleteAll()
      local entityToAdd = testData[2]
      repo:Save(entityToAdd)

      local result = repo:FindByID(entityToAdd.id)
      assert.same(entityToAdd, result)
    end)
    it("fires an EntityDataReset event", function()
      repo:DeleteAll()

      addon:Advance()
      eventSpy:AssertPublished(repo.events.EntityDataReset, 1)
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
    local saveDataField, testData, tempAddon, tempEventSpy
    before_each(function()
      -- Save data is stored in a global field, so to use fresh save data
      -- we need to specify a different field for every test
      saveDataField = addon:CreateID("save-data-%i")
      testData = createTestEntities(3)
      tempAddon = builder:Build()
      tempAddon:Init()
      tempEventSpy = events:SpyOnEvents(tempAddon.AppEvents)
      repo = tempAddon:NewRepository("SaveDataTest")
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

      results = tempAddon:DecompressTable(result)
      assert.equals(1, #results)
      assert.same(entity, results[1])
    end)
    it("can load compressed data", function()
      repo:EnableCompression(true)
      local compressed = tempAddon:CompressTable(testData)
      tempAddon.SaveData:Save(saveDataField, compressed)
      repo:SetSaveDataSource(saveDataField)
      tempAddon:Advance()

      local results = repo:FindAll()
      assert.equals(3, #results)

      local result = repo:FindByID(results[1].id)
      assert.same(results[1], result)
    end)
    it("fires an EntityDataLoaded event", function()
      repo:EnableCompression(true)
      local compressed = tempAddon:CompressTable(testData)
      tempAddon.SaveData:Save(saveDataField, compressed)
      repo:SetSaveDataSource(saveDataField)

      tempAddon:Advance()
      tempEventSpy:AssertPublished(repo.events.EntityDataLoaded, 1)
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
    it("fires an EntityDataLoaded event", function()
      for _, v in pairs(testData) do
        v.id = addon:CreateID("testData-%i")
      end
      repo:SetTableSource(testData)

      addon:Advance()
      eventSpy:AssertPublished(repo.events.EntityDataLoaded, 1)
    end)
  end)
  describe("Timestamps", function()
    local entity
    before_each(function()
      repo:EnableWrite(true)
      repo:EnablePrimaryKeyGeneration(true)
      repo:EnableTimestamps(true)

      entity = createTestEntity()
      assert.is_nil(entity.cd)
      assert.is_nil(entity.ud)
    end)
    describe("for direct-read entities", function()
      before_each(function()
        repo:EnableDirectRead(true)
      end)
      it("can set create/update dates on new entities", function()
        local ts = addon.G.time()
        repo:Save(entity)
        assert(entity.cd >= ts, "Expected create date to be greater than or equal to the current time")
        assert.equals(entity.cd, entity.ud)
      end)
      it("can set update date on existing entities", function()
        repo:Save(entity)
        local targetTime = entity.cd + 10
        while (addon.G.time() < targetTime) do end
        repo:Save(entity)
        assert(entity.ud >= targetTime, "Expected update date to be greater than or equal to the current time")
        assert(entity.ud > entity.cd, "Expected update date to be greater than create date")
      end)
    end)
    describe("for non-direct-read entities", function()
      it("can set create/update dates on new entities", function()
        local ts = addon.G.time()
        repo:Save(entity)
        entity = repo:FindByID(entity.id)
        assert(entity.cd >= ts, "Expected create date to be greater than or equal to the current time")
        assert.equals(entity.cd, entity.ud)
      end)
      it("can set update date on existing entities", function()
        repo:Save(entity)
        entity = repo:FindByID(entity.id)
        local targetTime = entity.cd + 10
        while (addon.G.time() < targetTime) do end
        repo:Save(entity)
        entity = repo:FindByID(entity.id)
        assert(entity.ud >= targetTime, "Expected update date to be greater than or equal to the current time")
        assert(entity.ud > entity.cd, "Expected update date to be greater than create date")
      end)
    end)
  end)
end)