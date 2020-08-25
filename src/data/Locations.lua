local _, addon = ...

addon.Locations = addon:NewRepository("Location", "locationId")
addon.Locations:SetSaveDataSource("Locations")
addon.Locations:EnableWrite(true)
addon.Locations:EnableCompression(false)
addon.Locations:EnableGlobalSaveData(true)
addon.Locations:EnableTimestamps(true)
addon.Locations:EnablePrimaryKeyGeneration(true)