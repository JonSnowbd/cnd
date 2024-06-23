local obj = require "cnd.obj"
local mth = require "cnd.mth"

---@class cnd.scn.entity : cnd.obj
---@field name string|nil The entities name.
---@field constructed boolean
---@field parent cnd.scn
---@field queuedForDeletion boolean
---@field layer integer the layer handle 
---@field enabled boolean if true, subscriptions are ran.
---@field id integer
---@field position cnd.mth.v2
---@field rotation number
---@field scale cnd.mth.v2
---@field origin cnd.mth.v2
---@field subscriptions table<table,fun(entity: cnd.scn.entity, data: any|nil)>
---@field tags table<any,boolean> A hash set of tags, used in the mirror feature.
---@overload fun(cnd.scn: cnd.scn): cnd.scn.entity
local entity = obj:extend()

---@param scn cnd.scn
function entity:new(scn)
    self.parent = scn
    self.constructed = false
    self.id = scn:getID()
    self.enabled = true

    self.position = mth.v2(0, 0)
    self.rotation = 0.0
    self.scale = mth.v2(1, 1)
    self.origin = mth.v2(0.5, 0.5)

    self.queuedForDeletion = false

    self.layer = -1
    self.tags = {}

    self.subscriptions = {}
end

function entity:onConstruct(...)
end
function entity:onEnterLayer()
end
function entity:onExitLayer()
end

---@param phase any The cnd.scn phase this subscription runs on.
---@param fn fun(ent: cnd.scn.entity, data: any|nil)
function entity:subscribe(phase, fn)
    if self.subscriptions[phase] ~= nil then
        self.parent:warn(self.id, self.layer, "Attempted to subscribe to a phase that I was already subscribed to. Overriding logic.")
    end
    self.subscriptions[phase] = fn
    local layer = self.parent:getLayer(self.layer)
    layer:notifyEntityAddedSubscription(self, phase)
end

function entity:unsubscribe(phase)
    if self.subscriptions[phase] ~= nil then
        self.parent:warn(self.id, self.layer, "Attempted to unsubscribe from a phase I was never subscribed to.")
    end
    self.subscriptions[phase] = nil
    local layer = self.parent:getLayer(self.layer)
    layer:notifyEntityRemovedSubscription(self, phase)
end

---@param tag any
function entity:tag(tag)
    self.tags[tag] = true
    self.parent:triggerEvent(self.parent.event.tagModified, {
        target = self,
        tag = tag,
        wasAdded = true
    })
end

---@param tag any
function entity:untag(tag)
    self.tags[tag] = nil
    self.parent:triggerEvent(self.parent.event.tagModified, {
        target = self,
        tag = tag,
        wasAdded = false
    })
end

function entity:disable()
    self.enabled = false
end
function entity:enable()
    self.enabled = true
end

function entity:delete()
    if self.layer == -1 then
        self.enabled = false
    else
        local layer = self.parent:getLayer(self.layer)
        layer:removeEntity(self)
        self.enabled = false
    end
    self.queuedForDeletion = true
end

function entity:move(x, y)
    self.position[1], self.position[2] = self.position[1]+x, self.position[2]+y
end
function entity:rotate(rads)
    self.rotation = self.rotation + rads
end
function entity:scaleBy(sx, sy)
    self.scale[1], self.scale[2] = self.scale[1]*sx, self.scale[2]*sy
end
function entity:setScale(sx, sy)
    self.scale[1], self.scale[2] = sx, sy
end
function entity:setPosition(x, y)
    self.position[1], self.position[2] = x, y
end
function entity:setRotation(rads)
    self.rotation = rads
end

function entity:__tostring()
    if self.name ~= nil then return self.name else return "ent#"..tostring(self.id) end
end

--- Requires a playground attached to cnd.scn.
---@param shader string
---@param data table|nil
function entity:renderSetShader(shader, data)
    if self.parent.playground then
        self.parent.playground:bindShader(shader, data)
    end
end
--- Requires a playground attached to cnd.scn.
function entity:renderClearShader()
    if self.parent.playground then
        local layer = self.parent:getLayer(self.layer)
        if layer.defaultShader then
            self.parent.playground:bindShader(layer.defaultShader)
        else
            love.graphics.setShader()
        end
    end
end

--- Automatic render of many types, slower than normal rendering, but convenient.
--- Positional data offsets any current entity transforms.
---@param object love.Font|love.Texture|cnd.res.imagesheet|cnd.res.sprite|cnd.res.ninepatch
---@param data any|nil Font = String, Texture = Quad|Nil, Sprite = Nil, NinePatch = {w,h} pixel size, ImageSheet = {x,y} index
function entity:render(object, data, x, y, rot, xs, ys)
end

return entity