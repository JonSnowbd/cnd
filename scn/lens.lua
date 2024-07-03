local entity = require "cnd.scn.entity"
local arr = require "cnd.arr"

--- A lens tracks tagged entities. When an entity gains or loses a tag, this will
--- store it or forget it. An optimized way to get all entities of a tag.
---@class lens : cnd.scn.entity
---@field debug boolean if true, additions and changes are logged.
---@field tracking any a list of tags to listen for
---@field targets cnd.arr list of every entity that the lens has found so far.
---@field layerOnly boolean if true, only tracks entities in this layer.
---@field cache table<cnd.scn.entity,boolean> a cache for fast "contains" checks.
---@field newEntity fun(ent: cnd.scn.entity)|nil a callback for when an entity gets added. This is called for every entity in the scene when added to a layer.
---@field lostEntity fun(ent: cnd.scn.entity)|nil a callback for when an entity gets removed. This is called for every entity when removed from a layer.
local lens = entity:extend()

---@private
---@param other cnd.scn.entity
function lens:_add(other)
    self.cache[other] = true
    self.targets:append(other)
    self.parent:info(self.id, self.layer, "Added new entity to "..self.name..": "..other.name)
    if self.newEntity ~= nil then
        self.newEntity(other)
    end
end
---@private
---@param other cnd.scn.entity
function lens:_remove(other)
    if self.cache[other] ~= nil then
        self.targets:removeItem(other)
        self.cache[other] = nil
        if self.lostEntity ~= nil then
            self.lostEntity(other)
        end
    end
end

---@param data cnd.scn.tagModified
function lens:modified(data)
    if data.addedTo ~= nil then
        ---@type cnd.scn.entity
        local target = data.addedTo
        if target:hasTag(self.tracking) then
            self:_add(target)
        end
    end

    if data.removedFrom ~= nil then
        ---@type cnd.scn.entity
        local target = data.removedFrom
        if target:hasTag(self.tracking) then
            self:_remove(target)
        end
    end
end

---@param tag any
---@param debugOn boolean|nil
function lens:onConstruct(tag, debugOn)
    if tag == nil then
        self.parent:crash(self.id, self.layer, "Failed to supply a tag to track.")
    end
    self.debug = debugOn or false
    self.tracking = tag
    self.targets = arr()
    self.name = "lens#"..self.id
    self:subscribe(self.parent.event.tagModified, lens.modified)
end

function lens:onEnterLayer()
    ---@type cnd.scn.layer
    local layer = self.parent:getLayer(self.layer)
    for ent in layer:iterate() do
        if ent:hasTag(self.tracking) then
            self:_add(ent)
        end
    end
end

function lens:onExitLayer()
end

return lens