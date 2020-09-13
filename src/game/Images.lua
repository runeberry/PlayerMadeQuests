local _, addon = ...

local textureBasePath = [[Interface\AddOns\PlayerMadeQuests\assets\img\]]

local textures = {
  ["Logo"] = {
    filename = "pmq_logo.tga",
    width = 128,
    height = 128,
  }
}

function addon:CreateImageFrame(imageName, parentFrame)
  assert(type(imageName) == "string", "An imageName must be provided")
  local textureInfo = textures[imageName]
  assert(textureInfo, imageName.." is not a recognized image name")

  parentFrame = parentFrame or addon.G.UIParent

  local imgFrame = parentFrame:CreateTexture(nil, "ARTWORK")
  imgFrame:SetSize(textureInfo.width, textureInfo.height)
  imgFrame:SetTexture(textureBasePath..textureInfo.filename)

  return imgFrame
end