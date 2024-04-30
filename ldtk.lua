local Object = require("dep.classic")
local json = require("dep.json")

local ldtk = {}

---@class ldtk.FieldInstance : Object
---@field uid string the unique identifier of the instance.
---@field type string the type of field instance this is, int, float, string, enum(type), bool
---@field gridPosition? number[] Where this field instance points to, if anywhere
---@field value any do some smart things on your end to figure this out, check type or something
---@field refWorld? string the referenced world IID
---@field refLevel? string the referenced level IID
---@field refLayer? string the referenced layer IID
---@field refEntity? string the referenced entity IID
local FieldInstance = Object:extend()

---@param object table the object from the decoded ldtk project
function FieldInstance:new(object)
    self.uid = object["defUid"]
    self.type = object["__type"]
    if object["cx"] ~= nil then
        self.gridPosition = {object["cx"], object["cy"]}
    end
    if object["entityIid"] ~= nil then
        self.refEntity = object["entityIid"]
    end
    if object["layerIid"] ~= nil then
        self.refLayer = object["layerIid"]
    end
    if object["levelIid"] ~= nil then
        self.refLevel = object["levelIid"]
    end
    if object["worldIid"] ~= nil then
        self.refWorld = object["worldIid"]
    end
end


---@class ldtk.Entity : Object
---@field parent ldtk.Layer
---@field iid string the unique identifier of the instance.
---@field identifier string the type name
---@field gridIndex integer[] where it was placed in the levels grid
---@field pivot number[] normalized floats, 0.0 = left, 0.5 = center, 1 = right side
---@field size number[] the size of the entity itself.
---@field position number[] pixel position in the level
---@field worldPosition number[] pixel position in the world
---@field fields ldtk.FieldInstance[] if the object type had field values, they're in here.
local Entity = Object:extend()

---@param object table the object from the decoded ldtk project
function Entity:new(object, parent)
    self.parent = parent
    self.iid = object["iid"]
    self.identifier = object["__identifier"]
    self.gridIndex = object["__grid"]
    self.pivot = object["__pivot"]
    self.size = {object["width"], object["height"]}
    self.position = object["px"]
    self.worldPosition = {object["__worldX"], object["__worldY"]}
    self.fields = {}
    local fieldCount = #object["fieldInstances"]
    for i=1,fieldCount do
        self.fields[#self.fields+1] = FieldInstance(object["fieldInstances"][i])
    end
end

---@class ldtk.Tile
---@field position number[] pixel position in layer space
---@field src number[] src position in pixels
---@field alpha number transparency, 0.0 = invisibile, 1.0 = fully visible
local Tile = Object:extend()

function Tile:new(object)
    self.position = object["px"]
    self.src = object["src"]
    self.alpha = object["a"]
    -- TODO flip bits
end

---@class ldtk.Tileset
---@field parent ldtk.Project
---@field image love.Image the loaded texture via love
---@field customData table[] an array of tables, with the format {data=string, tileId=int}
---@field identifier string the name the user gave it
---@field padding number the space from the image edge to the tiles
---@field spacing number the space between every tile
---@field tags string[] user defined organization tags
---@field gridSize integer how large each tile is
---@field uid integer the uid of the tileset
local Tileset = Object:extend()

function Tileset:new(object, image, parent)
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

---@class ldtk.Layer
---@field parent ldtk.Level
---@field identifier string the layer's name assigned in ldtk
---@field iid string the layer's unique auto generated id
---@field visible boolean
---@field gridSize number
---@field offset number[] the offset of the layer in relation to the level, in pixels
---@field layerType "Entities"|"IntGrid"|"Tiles"|"AutoLayer"
---@field entities? ldtk.Entity[] if the layer is a entity layer, this will not be nil
---@field autotiles? ldtk.Tile[] if the layer is an auto tile layer, this will not be nil
---@field tiles? ldtk.Tile[] if the layer is a tile layer, this will not be nil
---@field intgrid? integer[][] the layout of this array is intgrid[y][x]. will not be nill for IntGrid layers
---@field tilesetUid? integer if tiles/autolayer this should point to the tileset used.
local Layer = Object:extend()

function Layer:new(object, parent)
    self.parent = parent
    self.identifier = object["__identifier"]
    self.layerType = object["__type"]
    self.visible = object["visible"]
    self.gridSize = object["__gridSize"]
    self.iid = object["iid"]
    self.offset = {object["__pxTotalOffsetX"], object["__pxTotalOffsetY"]}
    if object["__tilesetDefUid"] then
        self.tilesetUid = object["__tilesetDefUid"]
    end

    if self.layerType == "Entities" then
        self.entities = {}
        local entCount = #object["entityInstances"]
        for i=1,entCount do
            self.entities[#self.entities+1] = Entity(object["entityInstances"][i], self)
        end
    end
    if self.layerType == "AutoLayer" then
        self.autotiles = {}
        local tileCount = #object["autoLayerTiles"]
        for i=1,tileCount do
            self.autotiles[#self.autotiles+1] = Tile(object["autoLayerTiles"][i])
        end
    end
    if self.layerType == "Tiles" then
        self.tiles = {}
        local tileCount = #object["gridTiles"]
        for i=1,tileCount do
            self.tiles[#self.tiles+1] = Tile(object["gridTiles"][i])
        end
    end
    if self.layerType == "IntGrid" then
        self.intgrid = {}
        local w = object["__cWid"]
        local h = object["__cHei"]

        for y=1,h do
            self.intgrid[y] = {}
            for x=1,w do
                local _1dIndex = (y * w) + x
                self.intgrid[y][x] = object["intGridCsv"][_1dIndex]
            end
        end
    end
end

--- Takes all the tiles in the layer(if it is an autolayer or tile layer)
--- and writes it all into a sprite batch that is returned. You can just
--- `love.graphics.draw(theSpriteBatch)` and it works. the tiles are 
--- placed in the batch at tileposition+layerposition
---@return love.SpriteBatch?
function Layer:makeSpriteBatch()
    if self.tilesetUid == nil then return nil end

    ---@type ldtk.Tileset
    local tileset = nil
    for _, v in pairs(self.parent.parent.tilesets) do
        if v.uid == self.tilesetUid then
            tileset = v
            break
        end
    end

    if tileset == nil then return nil end

    local batch = love.graphics.newSpriteBatch(tileset.image, 1024, "static")

    local tiles = nil
    if self.layerType == "AutoLayer" then tiles = self.autotiles end
    if self.layerType == "Tiles" then tiles = self.tiles end
    if tiles == nil then return nil end
    for _, v in pairs(tiles) do
        local quad = love.graphics.newQuad(v.src[1], v.src[2], self.gridSize, self.gridSize, tileset.image:getWidth(), tileset.image:getHeight())
        batch:add(quad, v.position[1]+self.offset[1], v.position[2]+self.offset[2])
    end

    return batch
end

---@class ldtk.Level
---@field parent ldtk.Project
---@field identifier string the level's name assigned in ldtk
---@field iid string the level's unique auto generated id
---@field uid string 
---@field worldPosition number[] the level's position on the world chart in pixels
---@field worldSize number[] the level's size on the world chart (this is also the real size of the level)
---@field worldDepth integer the level's depth in the world chart
---@field layers ldtk.Layer[] the layers inside this level
local Level = Object:extend()

function Level:new(object, parent)
    self.parent = parent
    self.identifier = object["identifier"]
    self.iid = object["iid"]
    self.uid = object["uid"]
    self.worldPosition = {object["worldX"], object["worldY"]}
    self.worldSize = {object["pxWid"], object["pxHei"]}
    self.worldDepth = object["worldDepth"]
    self.layers = {}
    local layerCount = #object["layerInstances"]
    for i=1,layerCount do
        self.layers[#self.layers+1] = Layer(object["layerInstances"][i], self)
    end
end

function Level:getLayer(name)
    for k, v in pairs(self.layers) do
        if v.identifier == name then return v end
    end
end

---@class ldtk.Project
---@field folder string the project file's folder, for resolving tilesets.
---@field raw table the raw decoded ldtk project json in lua table format
---@field levels ldtk.Level[]
---@field tilesets ldtk.Tileset[]
local Project = Object:extend()

---@param fileData string the contents of the ldtk file to parse
---@param filePath? string
function Project:new(fileData, filePath)
    self.raw = json.decode(fileData)
    self.levels = {}
    if filePath then
        self.folder = filePath:match("(.*/)")
    end
    local levelCount = #self.raw["levels"]

    for i=1,levelCount do
        self.levels[#self.levels+1] = Level(self.raw["levels"][i], self)
    end

    if filePath then
        local tiles = self.raw["defs"]["tilesets"]
        local tilesetCount = #tiles
        self.tilesets = {}
        for i=1,tilesetCount do
            local path = tiles[i]["relPath"]
            local img = love.graphics.newImage(self.folder..path)
            self.tilesets[#self.tilesets+1] = Tileset(tiles[i], img, self)
        end
    end
end

---@param name string the identifier of the level.
---@return ldtk.Level?
function Project:getLevel(name)
    for k, v in pairs(self.levels) do
        if v.identifier == name then return v end
    end
    return nil
end

ldtk.Project = Project
ldtk.Level = Level
ldtk.Layer = Layer
ldtk.Entity = Entity
ldtk.FieldInstance = FieldInstance
ldtk.Tileset = Tileset
ldtk.Tile = Tile

---@param fileData string read the entire file and pass it here.
---@param filePath string the path of the file itself. pass nil if mem loading, disables tilesets and separate levels
---@return ldtk.Project
ldtk.load = function(fileData, filePath)
    ---@type ldtk.Project
    LDtkProject = Project(fileData, filePath)
    return LDtkProject
end

return ldtk