local entity = require "cnd.scn.entity"
local scn = require "cnd.scn"

---@class Lens : cnd.scn.entity
---@field targets cnd.scn.entity[]
local Lens = entity:extend()

function Lens:onConstruct()
    self.targets = {}
    self.name = "Lens#"..self.id
    self:subscribe(scn.event.tagModified, function (ent, data)
        ---@type boolean
        local wasAdded = data.wasAdded or false
        local tag = data.tag.name or "Unknown"
    end)
end


return Lens