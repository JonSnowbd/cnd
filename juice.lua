---@diagnostic disable: param-type-mismatch
local Object = require "dep.classic"
local interp = require "dep.interp"
local vec    = require "dep.vec"


---@class Juice.Context
---@field id string
---@field parent Juice
---@field dt number
---@field isVector boolean
---@field value number[]|number
---@field target number[]|number
---@field previousValue number[]|number
---@field previousTarget number[]|number
---@field velocity number[]|number
---@field requestedOn integer
---@field state table
---@overload fun(id: string, parent: Juice, value: number[]|number, target: number[]|number, isVector: boolean): Juice.Context
local Context = Object:extend()

---@param id string
---@param parent Juice
---@param value number[]|number
---@param target number[]|number
---@param isVector boolean
function Context:new(id, parent, value, target, isVector)
    self.dt = 0.0
    self.id = id
    self.parent = parent
    self.isVector = isVector
    self.requestedOn = parent.frame
    if isVector then
        self.value = {}
        self.value[1], self.value[2] = value[1], value[2]
        self.previousValue = {}
        self.previousValue[1], self.previousValue[2] = value[1], value[2]
        self.target = {}
        self.target[1], self.target[2] = target[1], target[2]
        self.previousTarget = {}
        self.previousTarget[1], self.previousTarget[2] = target[1], target[2]
        self.velocity = {0.0, 0.0}
    else
        self.value = value
        self.previousValue = value
        self.target = target
        self.previousTarget = target
        self.velocity = 0.0
    end
    self.state = {}
end

---@return boolean fresh true if valid data.
function Context:fresh()
    return (self.parent.frame - self.requestedOn) < 10
end


---@class Juice.PhysicsMechanism : Object
local PhysicsMechanism = Object:extend()

---@param context Juice.Context
function PhysicsMechanism:affector(context)
end
---@param context Juice.Context
function PhysicsMechanism:postAffector(context)
end


---@class Juice.LinearForceMechanism : Juice.PhysicsMechanism
---@field force number How strong the pull towards target is, in pixels per second.
---@overload fun(force: number): Juice.LinearForceMechanism
local LinearForceMechanism = PhysicsMechanism:extend()

---@param force number
function LinearForceMechanism:new(force)
    self.force = force
end

---@param context Juice.Context
function LinearForceMechanism:affector(context)
    if context.isVector then
        local x,y = vec.sub(context.target[1], context.target[2], context.value[1], context.value[2])
        x,y = vec.normalize(x,y)
        x,y = vec.scale(x,y, self.force*context.dt)
        context.velocity[1] = context.velocity[1] + x
        context.velocity[2] = context.velocity[2] + y
    else
        local diff = interp.sign(context.target - context.value)
        context.velocity = context.velocity + (diff * self.force * context.dt)
    end
    
end
---@param context Juice.Context
function LinearForceMechanism:postAffector(context)
end

---@class Juice.DampForceMechanism : Juice.PhysicsMechanism
---@field constantDamp number|nil
---@field proximityDamp number|nil
---@field proximityRadius number|nil
---@overload fun(constant: number|nil, proxDamp: number|nil, proxRad: number|nil): Juice.DampForceMechanism
local DampForceMechanism = PhysicsMechanism:extend()

---comment
---@param constant number|nil
---@param prox number|nil
---@param rad number|nil
function DampForceMechanism:new(constant, prox, rad)
    self.constantDamp = constant
    self.proximityDamp = prox
    self.proximityRadius = rad
end

---@param context Juice.Context
function DampForceMechanism:affector(context)
    if context.isVector then
        -- local x, y = vec.scale(context.velocity[1], context.velocity[2], (self.constantDamp * context.dt))
        if self.constantDamp then
            context.velocity[1], context.velocity[2] = vec.scale(context.velocity[1], context.velocity[2], 1.0-(self.constantDamp*context.dt))
        end
        if self.proximityDamp ~= nil and self.proximityRadius ~= nil then
            local dist = vec.distance(context.value[1], context.value[2], context.target[1], context.target[2])
            local prox = interp.clamp((dist / self.proximityRadius), 0.0, 1.0)
            local damp = interp.lerp(1.0, 0.0, prox, interp.circ.out)
            context.velocity[1], context.velocity[2] = vec.scale(context.velocity[1], context.velocity[2], 1.0-(self.proximityDamp*damp*context.dt))
        end
    else
        if self.constantDamp ~= nil then
            context.velocity = context.velocity * (1.0-(self.constantDamp*context.dt))
        end
        if self.proximityDamp ~= nil and self.proximityRadius ~= nil then
            local dist = math.abs(context.target - context.value)
            local prox = interp.clamp((dist / self.proximityRadius), 0.0, 1.0)
            local damp = interp.lerp(1.0, 0.0, prox, interp.circ.out)
            context.velocity = context.velocity * (1.0-(self.proximityDamp*damp*context.dt))
        end
    end
end
---@param context Juice.Context
function DampForceMechanism:postAffector(context)
end

---@class Juice.InheritVelocityMechanism : Juice.PhysicsMechanism
---@field amount number
---@field proximityRadius number|nil
---@overload fun(amount: number, proxRad: number|nil): Juice.InheritVelocityMechanism
local InheritVelocityMechanism = PhysicsMechanism:extend()

---@param amount number
---@param rad number|nil
function InheritVelocityMechanism:new(amount, rad)
    self.amount = amount
    self.proximityRadius = rad
end

---@param context Juice.Context
function InheritVelocityMechanism:affector(context)
    if context.isVector then
        local dx, dy = vec.sub(context.target[1], context.target[2], context.previousTarget[1], context.previousTarget[2])
        dx, dy = vec.scale(dx, dy, self.amount*context.dt)
        if self.proximityRadius ~= nil then
            local dist = vec.distance(context.value[1], context.value[2], context.target[1], context.target[2])
            local prox = interp.clamp((dist / self.proximityRadius), 0.0, 1.0)
            local damp = interp.lerp(1.0, 0.0, prox, interp.circ.out)
            dx, dy = vec.scale(dx, dy, damp)
        else
            context.velocity[1], context.velocity[2] = vec.add(context.velocity[1], context.velocity[2], dx, dy)
        end
    else
        local delta = (context.target - context.previousTarget) * (self.amount * context.dt)

        if self.proximityRadius ~= nil then
            local dist = math.abs(context.target - context.value)
            local prox = interp.clamp((dist / self.proximityRadius), 0.0, 1.0)
            local damp = interp.lerp(1.0, 0.0, prox, interp.circ.out)
            delta = delta * damp
        end
        context.velocity = context.velocity + delta
    end
end
---@param context Juice.Context
function InheritVelocityMechanism:postAffector(context)
end

---@class Juice.ConstantApproachMechanism : Juice.PhysicsMechanism
---@field amount number
---@overload fun(amount: number): Juice.ConstantApproachMechanism
local ConstantApproachMechanism = PhysicsMechanism:extend()

---@param amount number
function ConstantApproachMechanism:new(amount)
    self.amount = amount
end

---@param context Juice.Context
function ConstantApproachMechanism:affector(context)
end
---@param context Juice.Context
function ConstantApproachMechanism:postAffector(context)
    local force = self.amount * context.dt
    if context.isVector then
        local dx, dy = vec.sub(context.target[1], context.target[2], context.value[1], context.value[2])
        if force >= vec.length(dx, dy) then
            context.value[1], context.value[2] = context.target[1], context.target[2]
        else
            dx, dy = vec.normalize(dx, dy)
            dx, dy = vec.scale(dx, dy, force)
            context.value[1], context.value[2] = vec.add(context.value[1], context.value[2], dx, dy)
        end
    else
        local diff = context.target-context.value
        if force >= math.abs(diff) then
            context.value = context.target
        else
            local sign = interp.sign(diff) * force
            context.value = context.value + sign
        end
    end
end

---@class Juice.PhysicsProfile : Object
---@field mechanisms Juice.PhysicsMechanism[]
---@overload fun(): Juice.PhysicsProfile
local PhysicsProfile = Object:extend()

function PhysicsProfile:new()
    self.mechanisms = {}
end

---comment
---@param mechanism Juice.PhysicsMechanism
function PhysicsProfile:addMechanism(mechanism)
    self.mechanisms[#self.mechanisms+1] = mechanism
end

---@class Juice : Object
---@field cache table<string, Juice.Context>
---@field bits table<string, any>
---@field frame integer
---@field timeScale number
local Juice = Object:extend()

Juice.PhysicsProfile = PhysicsProfile
Juice.PhysicsMechanism = PhysicsMechanism
Juice.Context = Context
Juice.TagWorldDraw = "__tagWorldDraw"
Juice.TagScreenDraw = "__tagScreenDraw"
Juice.TagFinalDraw = "__tagFinalDraw"

function Juice:new()
    self.cache = {}
    self.frame = 0
    self.timeScale = 1.0
    self.bits = {}
    self.bits.base = {}
end

--- Loose, slow, overshoots often.
---@type Juice.PhysicsProfile
Juice.Smoothdamp = PhysicsProfile()
Juice.Smoothdamp:addMechanism(LinearForceMechanism(10.5))
Juice.Smoothdamp:addMechanism(DampForceMechanism(1.25, 6.0, 80.0))
Juice.Smoothdamp:addMechanism(ConstantApproachMechanism(10.0))

--- Fast, small overshoots.
---@type Juice.PhysicsProfile
Juice.Tight = PhysicsProfile()
Juice.Tight:addMechanism(LinearForceMechanism(15))
Juice.Tight:addMechanism(DampForceMechanism(2, 20.0, 80.0))
Juice.Tight:addMechanism(ConstantApproachMechanism(10.0))

--- Suitable for gameplay elements the camera tracks. Not too wild.
---@type Juice.PhysicsProfile
Juice.Gameplay = PhysicsProfile()
Juice.Gameplay:addMechanism(LinearForceMechanism(6))
Juice.Gameplay:addMechanism(DampForceMechanism(1, 20.0, 40.0))
Juice.Gameplay:addMechanism(ConstantApproachMechanism(15.0))

--- Moves the number from current towards towards. 
---@param current number
---@param towards number
---@param id string
---@param profile? Juice.PhysicsProfile You can provide a physics profile to modify behaviour. Juice has some static members of defaults.
---@return number
function Juice:number(current, towards, id, profile)
    local prof = profile or Juice.Smoothdamp
    ---@type Juice.Context
    local ctx
    if self.cache[id] == nil or self.cache[id]:fresh() == false then
        self.cache[id] = Context(id, self, current, towards, false)
        ctx = self.cache[id]
    else
        ctx = self.cache[id]
    end
    local dt = love.timer.getDelta() * self.timeScale

    ctx.value = current
    ctx.target = towards
    ctx.requestedOn = self.frame
    ctx.dt = dt


    for i=1,#prof.mechanisms do
        prof.mechanisms[i]:affector(ctx)
    end
    ctx.value = ctx.value + ctx.velocity
    for i=1,#prof.mechanisms do
        prof.mechanisms[i]:postAffector(ctx)
    end

    ctx.previousTarget = ctx.target
    ctx.previousValue = ctx.value
    ---@diagnostic disable-next-line: return-type-mismatch
    return ctx.value
end
--- Moves the number from current towards towards. 
---@param current number[]
---@param towards number[]
---@param id string
---@param profile? Juice.PhysicsProfile You can provide a physics profile to modify behaviour. Juice has some static members of defaults.
---@return number
---@return number
function Juice:vector(current, towards, id, profile)
    local prof = profile or Juice.Smoothdamp
    ---@type Juice.Context
    local ctx
    if self.cache[id] == nil or self.cache[id]:fresh() == false then
        self.cache[id] = Context(id, self, current, towards, true)
        ctx = self.cache[id]
    else
        ctx = self.cache[id]
    end
    local dt = love.timer.getDelta() * self.timeScale

    ctx.value[1], ctx.value[2] = current[1], current[2]
    ctx.target[1], ctx.target[2] = towards[1], towards[2]
    ctx.requestedOn = self.frame
    ctx.dt = dt


    for i=1,#prof.mechanisms do
        prof.mechanisms[i]:affector(ctx)
    end
    local newX, newY = vec.add(ctx.value[1], ctx.value[2], ctx.velocity[1], ctx.velocity[2])
    ctx.value[1], ctx.value[2] = newX, newY
    for i=1,#prof.mechanisms do
        prof.mechanisms[i]:postAffector(ctx)
    end

    ctx.previousTarget[1], ctx.previousTarget[2] = ctx.target[1], ctx.target[2]
    ctx.previousValue[1], ctx.previousValue[2] = ctx.value[1], ctx.value[2]

    ---@diagnostic disable-next-line: return-type-mismatch
    return ctx.value[1], ctx.value[2]
end

---@param id string
---@param bit any
---@param world string|nil
function Juice:addBit(id, bit, world)
    if bit.update == nil or bit.draw == nil or bit.alive == nil then
        error("Dep.Juice: Bit "..tostring(bit).." failed to supply update, draw, and alive functions.")
    end
    if self.bits[world or "base"] == nil then
        self.bits[world or "base"] = {}
    end
    self.bits[world or "base"][id] = bit
end

function Juice:update()
    for k,v in pairs(self.bits) do
        for k2, v2 in pairs(v) do
            if v2:alive() == false then
                v[k2] = nil
            end
        end
    end
    self.frame = self.frame + 1
end

function Juice:flushUpdates()
    for k,v in pairs(self.bits) do
        for k2, v2 in pairs(v) do
            v2:update()
        end
    end
end

---@param tag any
---@param world string|nil bits can exist in different 'worlds'. useful if you have multiple running scenes that have their own bits.
function Juice:flushDraws(tag, world)
    for k,v in pairs(self.bits[world or "base"]) do
        v:draw(tag)
    end
end
return Juice