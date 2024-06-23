local obj = require "cnd.obj"
local mth = require "cnd.mth"

local field = require "cnd.ldtk.field"

---@class cnd.ldtk.entity : cnd.obj
---@field parent cnd.ldtk.layer
---@field iid string the unique identifier of the instance.
---@field identifier string the type name
---@field gridIndex integer[] where it was placed in the levels grid
---@field pivot cnd.mth.v2 normalized floats, 0.0 = left, 0.5 = center, 1 = right side
---@field size cnd.mth.v2 the size of the entity itself.
---@field position cnd.mth.v2 pixel position in the level
---@field worldPosition cnd.mth.v2|nil pixel position in the world
---@field fields cnd.ldtk.field[] if the object type had field values, they're in here.
---@overload fun(obj: table, parent: cnd.ldtk.layer): cnd.ldtk.entity
local entity = obj:extend()

---@param object table the object from the decoded ldtk project
---@param parent cnd.ldtk.layer
function entity:new(object, parent)
    self.parent = parent
    self.iid = object["iid"]
    self.identifier = object["__identifier"]
    self.gridIndex = {object["__grid"][1]+1, object["__grid"][2]+1}
    self.pivot = mth.v2(object["__pivot"][1],object["__pivot"][2])
    self.size = mth.v2(object["width"], object["height"])
    self.position = mth.v2(object["px"][1],object["px"][1])
    if parent.parent.parent.layout == "GridVania" or parent.parent.parent.layout == "Free" then
        self.worldPosition = mth.v2(object["__worldX"], object["__worldY"])
    end
    self.fields = {}
    local fieldCount = #object["fieldInstances"]
    for i=1,fieldCount do
        self.fields[#self.fields+1] = field(object["fieldInstances"][i])
    end
end

return entity