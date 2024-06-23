local obj = require("cnd.obj")
local mth = require("cnd.mth")
local json = require("cnd.json")

local level = require "cnd.ldtk.level"
local tileset = require "cnd.ldtk.tileset"

---@class cnd.ldtk
---@field iid string
---@field jsonVersion string
---@field folder string the ldtk file's folder, for resolving tilesets.
---@field raw table the raw decoded ldtk ldtk json in lua table format
---@field levels cnd.ldtk.level[]
---@field layout "Free"|"GridVania"|"LinearHorizontal"|"LinearVertical" the worlds layout
---@field worldGridSize cnd.mth.v2|nil the size of the entire world. Only in gridvanias.
---@field tilesets cnd.ldtk.tileset[]
---@overload fun(filepath: string):cnd.ldtk
local ldtk = obj:extend()

---@param filePath string
function ldtk:new(filePath)
    self.raw = json.decode(love.filesystem.read(filePath))
    if self.raw.worldLayout == nil then
        error("LDtk: external/multiple worlds are not supported yet.")
    end
    self.levels = {}
    self.folder = filePath:match("(.*/)")
    local levelCount = #self.raw["levels"]

    for i=1,levelCount do
        self.levels[#self.levels+1] = level(self.raw["levels"][i], self)
    end

    self.iid = self.raw.iid
    self.jsonVersion = self.raw.jsonVersion
    self.layout = self.raw.worldLayout
    if self.layout == "GridVania" then
        self.worldGridSize = mth.v2(
            self.raw.worldGridWidth,
            self.raw.worldGridHeight
    )
    end

    if filePath then
        local tiles = self.raw["defs"]["tilesets"]
        local tilesetCount = #tiles
        self.tilesets = {}
        for i=1,tilesetCount do
            local path = tiles[i]["relPath"]
            local img = love.graphics.newImage(self.folder..path)
            self.tilesets[#self.tilesets+1] = tileset(tiles[i], img, self)
        end
    end
end

---@return cnd.ldtk.tileset|nil
function ldtk:getTileset(name)
    for i=1,#self.tilesets do
        if self.tilesets[i].identifier == name then return self.tilesets[i] end
    end
    return nil
end

---@param name string the identifier of the level.
---@return cnd.ldtk.level|nil
function ldtk:getLevel(name)
    for k, v in pairs(self.levels) do
        if v.identifier == name then return v end
    end
    return nil
end

return ldtk