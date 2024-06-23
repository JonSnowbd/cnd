local obj = require "cnd.obj"
local mth = require "cnd.mth"

local layer = require "cnd.ldtk.layer"

---@class cnd.ldtk.level
---@field parent cnd.ldtk
---@field identifier string the level's name assigned in ldtk
---@field iid string the level's unique auto generated id
---@field uid string 
---@field worldPosition cnd.mth.v2 the level's position on the world chart in pixels
---@field worldSize cnd.mth.v2 the level's size on the world chart (this is also the real size of the level)
---@field worldDepth integer the level's depth in the world chart
---@field layers cnd.ldtk.layer[] the layers inside this level
---@field fields table<string,any>
local level = obj:extend()

function level:new(object, parent)
    self.parent = parent
    self.identifier = object["identifier"]
    self.iid = object["iid"]
    self.uid = object["uid"]
    self.worldPosition = mth.v2(object["worldX"], object["worldY"])
    self.worldSize = mth.v2(object["pxWid"], object["pxHei"])
    self.worldDepth = object["worldDepth"]
    self.layers = {}
    self.fields = {}
    local layerCount = #object["layerInstances"]
    for i=1,layerCount do
        self.layers[#self.layers+1] = layer(object["layerInstances"][i], self)
    end
    for i=1,#object["fieldInstances"] do
        self.fields[object["fieldInstances"][i]["__identifier"]] = object["fieldInstances"][i]["__value"]
    end
end

---@param fieldName string
---@return nil|string|number|integer|table|boolean
function level:getField(fieldName)
    return self.fields[fieldName]
end

---@param name string
---@return cnd.ldtk.layer|nil
function level:getLayer(name)
    for k, v in pairs(self.layers) do
        if v.identifier == name then return v end
    end
    return nil
end

return level