---@diagnostic disable: param-type-mismatch
local obj = require "cnd.obj"

-- This isnt ready yet. Also not sure if it even stays, this might be overcomplicated.

---@class cnd.scn : cnd.obj
---@field objects any[] 
---@field clearColor number[] a 4 number array of the clear color used.
---@field metaLayer cnd.scn.layer A special logic-only layer that acts as if it was global. No matter what it runs after every other layer. Does not run in draw ever.
---@field fixedUpdateRate number
---@field fixedUpdateTimer number
---@field fixedUpdateTimeScale number
---@field coroutinesAfterEntities boolean if true, coroutines are ran after entity methods in each phase.
---@field layers integer[]
---@field runningIdentity integer
---@field updatePhases any[]
---@field drawPhases any[]
---@field playground cnd.scr|nil
---@field executionMode "sequential"|"simultaneous" How logic should be run. Sequential = "By every layer run each phase", simultaneous = "By every phase run each layer"
---@overload fun(): cnd.scn
local scn = obj:extend()

scn.phase = {
    input = {name="Input"},
    preUpdate = {name="Pre-Update"},
    update = {name="Update"},
    fixedUpdate = {name="Fixed Update"},
    postUpdate = {name="Post-Update"},

    preDraw = {name="Pre-Draw"},
    draw = {name="Draw"},
    postDraw = {name="Post-Draw"},
    debugDraw = {name="Debug Draw"},
}

scn.tag = {
    debug = {name="Debug"},
    meta = {name="Meta"},
}

scn.event = {
    tagModified = {name="Tag Modified"},
}

scn.entity = require "cnd.scn.entity"
scn.layer = require "cnd.scn.layer"

---@type cnd.scr|nil
scn.defaultScr = nil

--- Customized warning
---@param ent integer|nil
---@param layer integer|nil
---@param message string
function scn:warn(ent, layer, message)
    local msg = "Scene"
    if ent ~= nil then
        msg = "|ENT#".. msg .. tostring(self.objects[ent])
    end
    if layer ~= nil then
        msg = "|LYR#" .. msg .. tostring(self.objects[layer])
    end

    print(msg.." >> '"..message.."'")
end

--- Customized crash message
---@param ent integer|nil
---@param layer integer|nil
---@param message string
function scn:crash(ent, layer, message)
    local msg = "!!Scene ERROR!!"
    if ent ~= nil then
        msg = " ENT#".. msg .. tostring(self.objects[ent])
    end
    if layer ~= nil then
        msg = " LYR#" .. msg .. tostring(self.objects[layer])
    end

    print(msg.." '"..message.."'")
    error(message)
end

function scn:onConstruct()
end
function scn:onUpdate()
end
function scn:onDraw()
end

function scn:new()
    self.objects = {}
    self.layers = {}
    self.runningIdentity = 0
    self.executionMode = "simultaneous"
    self.fixedUpdateRate = 60.0
    self.fixedUpdateTimer = 0.0
    self.fixedUpdateTimeScale = 1.0
    self.updatePhases = {
        scn.phase.input,
        scn.phase.preUpdate,
        scn.phase.update,
        scn.phase.postUpdate
    }
    self.drawPhases = {
        scn.phase.preDraw,
        scn.phase.draw,
        scn.phase.postDraw,
        scn.phase.debugDraw,
    }

    self.metaLayer = scn.layer(self, 999999)
    self.objects[self.metaLayer.id] = self.metaLayer
    self.metaLayer.space = "ethereal"

    self.clearColor = {0.3, 0.3, 0.3, 1.0}

    if scn.defaultScr ~= nil then
        self:addScreen(scn.defaultScr)
    end

    self:onConstruct()
end

---@param scr cnd.scr
function scn:addScreen(scr)
    self.scr = scr
end

function scn:getID()
    local id = self.runningIdentity
    self.runningIdentity = self.runningIdentity + 1
    return id
end

function scn:triggerPhase(layer, phase, data)
    if phase == scn.phase.fixedUpdate then
        local target = 1.0/self.fixedUpdateRate
        self.fixedUpdateTimer = self.fixedUpdateTimer + (love.timer.getDelta() * self.fixedUpdateTimeScale)
        while self.fixedUpdateTimer >= target do
            layer:sendPhase(scn.phase.fixedUpdate, target)
            self.fixedUpdateTimer = self.fixedUpdateTimer - target
        end
    else
        layer:sendPhase(phase, data)
    end
end

---@param event any The event marker
---@param data any Any data the entities subscribed should receive.
---@return any|nil response Every entity subscribed will receive the event, but the first entity to return something will have it forwarded via this.
function scn:triggerEvent(event, data)
    local ret = nil
    for i=1, #self.layers do
        ---@type cnd.scn.layer
        local layer = self.objects[self.layers[i]]
        if layer.receivesEvents then
            local val = layer:sendPhase(event, data)
            if ret == nil and val ~= nil then
                ret = val
            end
        end
    end

    local val = self.metaLayer:sendPhase(event, data)
    if ret == nil and val ~= nil then
        ret = val
    end

    return ret
end

---@param baseType cnd.scn.entity|nil
---@return integer
function scn:makeEntity(baseType)
    local class = baseType or scn.entity
    local ent = class(self)
    self.objects[ent.id] = ent
    return ent.id
end
---@param baseType cnd.scn.entity|nil The base type of the entity
---@param layerId integer|nil the layer this is going to. if nil, entity is sent to 
---@param ... any Variadic parameters to be passed into the construction function of the entity.
function scn:quickCreate(baseType, layerId, ...)
    local eid = self:makeEntity(baseType)
    return self:assignEntity(eid, layerId or self.metaLayer.id, ...)
end

function scn:sortLayers()
    local sortFn = function(left, right)
        return self.objects[left].priority > self.objects[right].priority
    end

    table.sort(self.layers, sortFn)
end

--- Creates an internal layer and returns its ID handle.
---@param priority integer Priority of the layer, higher = ran first.
---@param space "world"|"screen"|"ethereal"|nil The default space of the layer.
---@return integer layerId the layers id number.
function scn:makeLayer(priority, space)
    local lyr = scn.layer(self, priority)
    self.objects[lyr.id] = lyr
    self.layers[#self.layers+1] = lyr.id

    if space ~= nil then
        lyr.space = space
    end

    self:sortLayers()

    return lyr.id
end

---@param layerId integer
---@return cnd.scn.layer
function scn:getLayer(layerId)
    return self.objects[layerId]
end

--- Places an entity into the layer, does setup,
--- and returns the now functional entity.
---@param entityId integer
---@param layerId integer
---@param ... any Variadic of things passed to the constructor.
---@return cnd.scn.entity
function scn:assignEntity(entityId, layerId, ...)
    ---@type cnd.scn.layer
    local layer = self.objects[layerId]
    ---@type cnd.scn.entity
    local entity = self.objects[entityId]
    layer:addEntity(entity, ...)
    return entity
end

function scn:update()
    if self.executionMode == "sequential" then
        for i=1,#self.layers do
            ---@type cnd.scn.layer
            local layer = self.objects[self.layers[i]]
            for j=1, #self.updatePhases do
                self:triggerPhase(layer, self.updatePhases[j])
            end
        end
        local layer = self.metaLayer
        for j=1, #self.updatePhases do
            self:triggerPhase(layer, self.updatePhases[j])
        end
    else
        for i=1,#self.updatePhases do
            for j=1,#self.layers do
                ---@type cnd.scn.layer
                local layer = self.objects[self.layers[j]]
                self:triggerPhase(layer, self.updatePhases[i])
            end
            self:triggerPhase(self.metaLayer, self.updatePhases[i])
        end
    end

    self:onUpdate()
end

function scn:draw()
    if self.scr then
        self.scr:bind()
    end
    love.graphics.clear(self.clearColor[1],self.clearColor[2],self.clearColor[3],self.clearColor[4])
    if self.executionMode == "sequential" then
        for i=1,#self.layers do
            ---@type cnd.scn.layer
            local layer = self.objects[self.layers[i]]
            if layer.space == "ethereal" then
                goto continue
            end
            if self.scr and layer.space == "world" then
                self.scr:enableCamera()
            end
            for j=1, #self.drawPhases do
                self:triggerPhase(layer, self.drawPhases[j])
            end
            if self.scr and layer.space == "world" then
                self.scr:disableCamera()
            end
            ::continue::
        end
    else
        for i=1, #self.drawPhases do
            for j=1,#self.layers do
                ---@type cnd.scn.layer
                local layer = self.objects[self.layers[j]]
                if layer.space == "ethereal" then
                    goto continue
                end
                if self.scr and layer.space == "world" then
                    self.scr:enableCamera()
                end
                self:triggerPhase(layer, self.drawPhases[i])
                if self.scr and layer.space == "world" then
                    self.scr:disableCamera()
                end
                ::continue::
            end
        end
    end

    self:onDraw()
    if self.scr then
        self.scr:unbind()
    end
    self:composite()

end

function scn:composite()
    if self.scr then
        self.scr:draw()
    else
        love.graphics.setCanvas()
    end
end

return scn