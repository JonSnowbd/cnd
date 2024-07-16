local obj = require "cnd.obj"
local arr = require "cnd.arr"

---@param left cnd.scn.entity
---@param right cnd.scn.entity
local function sortEntity(left, right)
    if left.priority == right.priority then
        return left.id < right.id
    end
    return left.priority < right.priority
end

---@class cnd.scn.layer
---@field name string|nil
---@field enabled boolean
---@field space "world"|"screen"|"ethereal" The space this layer exists on. If "ethereal" draw phases will do nothing
---@field id integer
---@field priority integer higher = ran first
---@field entities cnd.arr
---@field enabledPhases table<any,cnd.arr>
---@field defaultShader string|nil If scene has a playground attached, this shader will be bound when its draw phase comes.
---@field receivesEvents boolean if true, event processing will pass through this layer.
---@overload fun(parent: cnd.scn, priority:integer): cnd.scn.layer
local layer = obj:extend()

---@param parent cnd.scn
---@param priority integer
function layer:new(parent, priority)
    self.id = parent:getID()
    self.enabled = true
    self.space = "world"
    self.priority = priority
    self.entities = arr()
    self.enabledPhases = {}
    self.receivesEvents = true
end

---@param entity cnd.scn.entity
---@param ... any if the entity is constructed when added, this is passed to the construction function.
function layer:addEntity(entity, ...)
    if entity.layer == -1 then
        entity.layer = self.id
        self.entities:append(entity)
        if entity.constructed == false then
            entity:onConstruct(...)
            entity.constructed = true
        else
            for k, v in pairs(entity.subscriptions) do
                self:notifyEntityAddedSubscription(entity, k)
            end
        end
        self.entities:sort(sortEntity)
        entity:onEnterLayer()
    end
end

--- Iterates every enabled entity.
---@return fun(): cnd.scn.entity
function layer:iterate()
    return self.entities:iter()
end

---comment
---@param entity cnd.scn.entity
function layer:removeEntity(entity)
    if entity.layer == self.id then
        for k, v in pairs(entity.subscriptions) do
            self:notifyEntityRemovedSubscription(entity, k)
        end
        self.entities:removeItem(entity)
        entity:onExitLayer()
        entity.layer = -1
    end
end

---@param phase any
---@param data any|nil
function layer:sendPhase(phase, data)
    local ret = nil
    if self.enabledPhases[phase] == nil then
        self.enabledPhases[phase] = arr()
        return ret
    end

    for ent in self.enabledPhases[phase]:iter() do
        if ent.enabled and ent.constructed then
            local val = ent.subscriptions[phase](ent, data)
            if val ~= nil and ret == nil then
                ret = val
            end
        end
    end

    return ret
end

--- Sorts a phase group.
---@param phase any
---@param sortFn (fun(left: cnd.scn.entity, right: cnd.scn.entity): boolean)|nil
function layer:resort(phase, sortFn)
    if self.enabledPhases[phase] ~= nil then
        self.enabledPhases[phase]:sort(sortFn or sortEntity)
        print("---- Layer: "..(phase.name or "UNK"))
        for ent in self.enabledPhases[phase]:iter() do
            print("Ent: "..tostring(ent))
        end
    end
end

--- INTERNAL
function layer:notifyEntityAddedSubscription(ent, phase)
    if self.enabledPhases[phase] == nil then
        self.enabledPhases[phase] = arr()
    end
    if self.enabledPhases[phase]:has(ent) then
        return -- Its already in there, we good
    end
    print("Adding "..tostring(ent).. " to phase "..(phase.name or "UNDEFINED"))
    self.enabledPhases[phase]:append(ent)
    self:resort(phase)
end
--- INTERNAL
function layer:notifyEntityRemovedSubscription(ent, phase)
    if self.enabledPhases[phase] == nil then
        self.enabledPhases[phase] = arr()
    end
    print("Removing "..tostring(ent).. " from phase "..(phase.name or "UNDEFINED"))
    self.enabledPhases[phase]:removeItem(ent)
end

function layer:__tostring()
    if self.name ~= nil then return self.name else return tostring(self.id) end
end

return layer