local _, addon = ...

local textureBasePath = [[Interface\AddOns\PlayerMadeQuests\assets\img\]]

-- todo: interface/icons/inv_misc_questionmark.blp

local textures = {
  ["Logo"] = {
    filename = "Logo.tga",
    width = 128,
    height = 128,
  },
  ["MenuIcons"] = {
    filename = "MenuIcons.tga",
    width = 128,
    height = 128,
  }
}

--- Creates a texture from the parent frame using the information stored in the table above
function addon:CreateImageTexture(parent, textureName, layer)
  layer = layer or "ARTWORK"

  assert(type(parent) == "table", "A parent frame must be provided")
  assert(type(textureName) == "string", "A textureName must be provided")
  local textureInfo = textures[textureName]
  assert(textureInfo, textureName.." is not a recognized textureName")

  local texture = parent:CreateTexture(nil, layer)
  texture:SetTexture(textureBasePath..textureInfo.filename)

  return texture, textureInfo.width, textureInfo.height
end