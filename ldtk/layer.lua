local obj = require "cnd.obj"
local entity = require "cnd.ldtk.entity"
local tile = require "cnd.ldtk.tile"
local mth = require "cnd.mth"

---@class cnd.ldtk.layer
---@field parent cnd.ldtk.level
---@field gridWidth integer how many cells in the x axis
---@field gridHeight integer how many cells in the Y axis
---@field identifier string the layer's name assigned in ldtk
---@field iid string the layer's unique auto generated id
---@field visible boolean
---@field gridSize number
---@field offset cnd.mth.v2 the offset of the layer in relation to the level, in pixels
---@field layerType "Entities"|"IntGrid"|"Tiles"|"Autolayer"
---@field entities? cnd.ldtk.entity[] if the layer is a entity layer, this will not be nil
---@field autotiles? cnd.ldtk.tile[] if the layer is an auto tile layer, this will not be nil
---@field tiles? cnd.ldtk.tile[] if the layer is a tile layer, this will not be nil
---@field intgrid? integer[][] the layout of this array is intgrid[y][x]. will not be nill for IntGrid layers
---@field tilesetUid? integer if tiles/autolayer this should point to the tileset used.
local layer = obj:extend()

function layer:new(object, parent)
    self.parent = parent
    self.gridWidth = object["__cWid"]
    self.gridHeight = object["__cHei"]
    self.identifier = object["__identifier"]
    self.layerType = object["__type"]
    self.visible = object["visible"]
    self.gridSize = object["__gridSize"]
    self.iid = object["iid"]
    self.offset = mth.v2(object["__pxTotalOffsetX"], object["__pxTotalOffsetY"])
    if object["__tilesetDefUid"] then
        self.tilesetUid = object["__tilesetDefUid"]
    end

    if self.layerType == "Entities" then
        self.entities = {}
        local entCount = #object["entityInstances"]
        for i=1,entCount do
            self.entities[#self.entities+1] = entity(object["entityInstances"][i], self)
        end
    end
    if self.layerType == "Autolayer" then
        self.autotiles = {}
        local tileCount = #object["autolayerTiles"]
        for i=1,tileCount do
            self.autotiles[#self.autotiles+1] = tile(object["autolayerTiles"][i])
        end
    end
    if self.layerType == "Tiles" then
        self.tiles = {}
        local tileCount = #object["gridTiles"]
        for i=1,tileCount do
            self.tiles[#self.tiles+1] = tile(object["gridTiles"][i])
        end
    end
    if self.layerType == "IntGrid" then
        self.intgrid = {}
        local w = object["__cWid"]
        local h = object["__cHei"]

        local x, y = 1, 1
        for i=1,#object["intGridCsv"] do
            local v = object["intGridCsv"][i]
            if self.intgrid[y] == nil then
                self.intgrid[y] = {}
            end
            self.intgrid[y][x] = v
            x = x + 1
            if x > w then
                x = 1
                y = y + 1
            end
        end
    end
end

--- Converts world coordinates to the layer indices.
---@param worldX number
---@param worldY number
---@return integer
---@return integer
function layer:toIndex(worldX, worldY)
    worldX, worldY = math.floor(((worldX+self.offset.x) / self.gridSize))+1, math.floor(((worldY+self.offset.y) / self.gridSize))+1
    return worldX, worldY
end

--- Returns true if the indices lay within the layer's bounds.
---@param indX integer
---@param indY integer
---@return boolean
function layer:isIndexValid(indX, indY)
    return indX >= 1 and indY >= 1 and indX <= self.gridWidth and indY <= self.gridHeight
end

--- Use this when the assumption is that there is only one of these kinds of entities.
--- Returns the first entity that has the type specified.
---@param type string
---@return cnd.ldtk.entity|nil
function layer:getEntity(type)
    for i=1,#self.entities do
        if self.entities[i].identifier == type then return self.entities[i] end
    end
    return nil
end

--- Returns an iterator that retrieves entities of the specified type.
---@param type string
---@return fun():cnd.ldtk.entity|nil iterator iterator that spits out entities
function layer:entitiesOfType(type)
    local i = 0
    return function()
        i = i + 1
        while i >= 1 and i <= #self.entities do
            if self.entities[i].identifier == type then
                return self.entities[i]
            else
                i = i + 1
            end
        end
        return nil
    end
end

---comment
---@param self cnd.ldtk.layer
---@param startX integer
---@param endX integer
---@param startY integer
---@param checked boolean[]
---@param identity integer
---@return integer[]
local function findBoundsRect(self, startX, endX, startY, checked, identity)
    local index = -1

    for y=startY+1,self.gridHeight do
        for x=startX,endX-1 do
            index = (y-1) * self.gridWidth + x
            local value = self.intgrid[y][x]

            if value ~= identity or checked[index] == true then
                for _x=startX,x do
                    index = (y-1) * self.gridWidth + _x
                    checked[index] = false
                end

                return {startX, startY, endX - startX, y-startY}
            end

            checked[index] = true
        end
    end
    return {startX,startY,endX-startX, self.gridHeight-startY}
end

--- If the layer is an intgrid, this merges neighbouring tiles into
--- large rectangles. Useful for collision and 'rooms' ala rimworld.
---@param identity integer the boxes will be made of tiles of this value
---@param callback fun(rect: integer[], gridsize: number) rects with index positions and sizes, x, y, w, h. 
function layer:greedyBoxes(identity, callback)
    if self.layerType ~= "IntGrid" then error("Cannot make islands from non-intgrids for layer "..self.identifier) end

    -- translated from https://github.com/prime31/Nez/blob/master/Nez.Portable/Assets/Tiled/Runtime/layer.Runtime.cs#L40
    -- and adapted to differentiate per tile rather than any tile.
    -- Highly recommend nez, awesome framework

    ---@type boolean[]
    local checked = {}
    ---@type integer[][]
    local rects = {}
    local startCol = -1

    for y=1,#self.intgrid do
        for x=1, #self.intgrid[y] do
            local ind = (y-1) * self.gridWidth + x
            local value = self.intgrid[y][x]
            if value == identity and (checked[ind] == nil or checked[ind] == false) then
                if startCol < 1 then
                    startCol = x
                end
                checked[ind] = true
            elseif value ~= identity or checked[ind] == true then
                if startCol >= 1 then
                    rects[#rects+1] = findBoundsRect(self, startCol, x, y, checked, identity)
                    startCol = -1
                end
            end
        end

        if startCol >= 1 then
            rects[#rects+1] = findBoundsRect(self, startCol, self.gridWidth, y, checked, identity)
            startCol = -1
        end
    end

    for i=1,#rects do
        -- print(rects[i][1]..'x'..rects[i][2]..'x'..rects[i][3]..'x'..rects[i][4])
        callback(rects[i], self.gridSize)
    end
end

--- Takes all the tiles in the layer(if it is an autolayer or tile layer)
--- and writes it all into a sprite batch that is returned. You can just
--- `love.graphics.draw(theSpriteBatch)` and it works. the tiles are 
--- placed in the batch at tileposition+layerposition
---@return love.SpriteBatch|nil
function layer:makeSpriteBatch()
    if self.tilesetUid == nil then return nil end

    ---@type cnd.ldtk.tileset
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
    if self.layerType == "Autolayer" then tiles = self.autotiles end
    if self.layerType == "Tiles" then tiles = self.tiles end
    if tiles == nil then return nil end
    for _, v in pairs(tiles) do
        local quad = love.graphics.newQuad(v.src.x, v.src.y, self.gridSize, self.gridSize, tileset.image:getWidth(), tileset.image:getHeight())
        batch:add(quad, v.position.x+self.offset.x, v.position.y+self.offset.y)
    end

    return batch
end

return layer