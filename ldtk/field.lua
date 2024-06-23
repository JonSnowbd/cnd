local obj = require "cnd.obj"
local mth = require "cnd.mth"

---@class cnd.ldtk.field : cnd.obj
---@field uid string the unique identifier of the instance.
---@field type string the type of field instance this is, int, float, string, enum(type), bool
---@field gridPosition? cnd.mth.v2 Where this field instance points to, if anywhere
---@field value any do some smart things on your end to figure this out, check type or something
---@field refWorld? string the referenced world IID
---@field refLevel? string the referenced level IID
---@field refLayer? string the referenced layer IID
---@field refEntity? string the referenced entity IID
local field = obj:extend()

---@param object table the object from the decoded ldtk project
function field:new(object)
    self.uid = object["defUid"]
    self.type = object["__type"]
    if object["cx"] ~= nil then
        self.gridPosition = mth.v2(object["cx"], object["cy"])
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

return field