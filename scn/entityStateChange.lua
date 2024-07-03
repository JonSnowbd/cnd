local obj = require "cnd.obj"

--- An event that notifies of disabled/enabled entities.
---@class cnd.scn.entityStateChange : cnd.obj
---@field enabled cnd.scn.entity|nil
---@field disabled cnd.scn.entity|nil
---@overload fun(): cnd.scn.entityStateChange
local entityStateChange = obj:extend()
entityStateChange.name = "Entity State Changed"

---@param obj cnd.scn.entity
---@return cnd.scn.entityStateChange
function entityStateChange.added(obj)
    local mod = entityStateChange()
    mod.enabled = obj
    return mod
end
---@param obj cnd.scn.entity
---@return cnd.scn.entityStateChange
function entityStateChange.removed(obj)
    local mod = entityStateChange()
    mod.disabled = obj
    return mod
end

return entityStateChange