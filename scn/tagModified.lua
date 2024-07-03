local obj = require "cnd.obj"

---@class cnd.scn.tagModified : cnd.obj
---@field addedTo cnd.scn.entity|nil
---@field removedFrom cnd.scn.entity|nil
---@overload fun(): cnd.scn.tagModified
local tagModified = obj:extend()
tagModified.name = "Entity Tag Added/Removed"

---@param obj cnd.scn.entity
---@return cnd.scn.tagModified
function tagModified.added(obj)
    local mod = tagModified()
    mod.addedTo = obj
    return mod
end
---@param obj cnd.scn.entity
---@return cnd.scn.tagModified
function tagModified.removed(obj)
    local mod = tagModified()
    mod.removedFrom = obj
    return mod
end

return tagModified