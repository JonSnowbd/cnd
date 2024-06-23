local obj = require "cnd.obj"

---@class cnd.ldtk.tileset
---@field parent cnd.ldtk
---@field image love.Image the loaded texture via love
---@field customData table[] an array of tables, with the format {data=string, tileId=int}
---@field identifier string the name the user gave it
---@field padding number the space from the image edge to the tiles
---@field spacing number the space between every tile
---@field tags string[] user defined organization tags
---@field gridSize integer how large each tile is
---@field uid integer the uid of the tileset
local tileset = obj:extend()

function tileset:new(object, image, parent)
    self.parent = parent
    self.image = image
    self.customData = object["customData"]
    self.identifier = object["identifier"]
    self.padding = object["padding"]
    self.spacing = object["spacing"]
    self.tags = object["tags"]
    self.gridSize = object["tileGridSize"]
    self.uid = object["uid"]
end

return tileset