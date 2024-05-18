local Object = require "dep.classic"
local interp = require "dep.interp"
local vec    = require "dep.vec"

---@class Juice.PhysicsMechanism
local PhysicsMechanism = Object:extend()

---@param context table
function PhysicsMechanism:onVector(context)
end
---@param context table
function PhysicsMechanism:onNumber(context)
end
---@class Juice.PhysicsProfile
---@field flatApproach? number the value approaches every frame at this rate, on top of velocity.
---@field linearForce? number
---@field constantDamp? number
---@field dampNearTarget? number[] [1] = how close for this to activate, [2] = multiplier
local PhysicsProfile = Object:extend()

function PhysicsProfile:new()
end

---@class Juice : Object
---@field cache table<string, table>
---@field frame integer
---@field timeScale number
local Juice = Object:extend()

Juice.PhysicsProfile = PhysicsProfile

function Juice:new()
    self.cache = {}
    self.frame = 0
    self.timeScale = 1.0
end

--- Loose, slow, overshoots often.
---@type Juice.PhysicsProfile
Juice.Smoothdamp = PhysicsProfile()
Juice.Smoothdamp.linearForce = 4.0
Juice.Smoothdamp.constantDamp = 2.0
Juice.Smoothdamp.dampNearTarget = {150.0, 5.0}

--- Very fast, with much overshoot. Good for items flowing towards
--- the player.
---@type Juice.PhysicsProfile
Juice.Tight = PhysicsProfile()
Juice.Tight.flatApproach = 2.0
Juice.Tight.linearForce = 8.0
Juice.Tight.constantDamp = 5.0
Juice.Tight.dampNearTarget = {200, 15.0}
--- Suitable for gameplay elements that dont need to be too juicy,
--- settles quickly into a position without too much overshoot.
---@type Juice.PhysicsProfile
Juice.Gameplay = PhysicsProfile()
Juice.Gameplay.linearForce = 8.0
Juice.Gameplay.flatApproach = 4.5
Juice.Gameplay.constantDamp = 19.0
Juice.Gameplay.dampNearTarget = {100.0, 30.0}

--- Moves the number from current towards towards. 
---@param current number
---@param towards number
---@param id string
---@param profile? Juice.PhysicsProfile You can provide a physics profile to modify behaviour. Juice has some static members of defaults.
---@return number
function Juice:number(current, towards, id, profile)
    profile = profile or Juice.Tight
    local dt = love.timer.getDelta() * self.timeScale
    local c
    if self.cache[id] ~= nil and (self.frame - self.cache[id]["lastAccess"]) < 4 then
        c = self.cache[id]
    else
        c = {
            lastAccess = self.frame,
            velocity = 0.0,
            previousTarget = towards,
        }
        self.cache[id] = c
    end

    local distance = towards-current
    local absDist = math.abs(distance)
    local dir = interp.sign(distance)
    -- 0.0 = completely ontop, 1.0 = farther than limit


    ---@type number
    local vel = c["velocity"]

    if profile.linearForce then
        vel = vel + (dir * profile.linearForce * dt)
    end
    if profile.constantDamp then
        vel = vel * (1.0-(profile.constantDamp*dt))
    end
    if profile.dampNearTarget then
        local locality = interp.clamp(interp.remap(absDist, 0.0, profile.dampNearTarget[1], 1.0, 0.0), 0.0, 1.0)
        locality = interp.lerp(0.0, 1.0, locality, interp.quart.into)
        local damp = 1.0-((profile.dampNearTarget[2]*dt) * locality)
        vel = vel * damp
    end


    c["lastAccess"] = self.frame
    c["velocity"] = vel
    c["previousTarget"] = towards
    if profile.flatApproach then
        local approach = profile.flatApproach * dt
        if interp.within(current+vel, towards, approach*1.3) then
            return towards
        end
        return current+vel+(approach*dir)
    else
        return current+vel
    end
end
--- Moves the number from current towards towards. 
---@param currentX number
---@param currentY number
---@param targetX number
---@param targetY number
---@param id string
---@param profile? Juice.PhysicsProfile You can provide a physics profile to modify behaviour. Juice has some static members of defaults.
---@return number X
---@return number Y
function Juice:vector(currentX, currentY, targetX, targetY, id, profile)
    profile = profile or Juice.Tight
    local dt = love.timer.getDelta() * self.timeScale
    local c
    if self.cache[id] ~= nil and (self.frame - self.cache[id]["lastAccess"]) < 4 then
        c = self.cache[id]
    else
        c = {
            lastAccess = self.frame,
            velocity = {0.0, 0.0},
            previousTarget = {targetX, targetY},
        }
        self.cache[id] = c
    end

    local distance = vec.distance(currentX, currentY, targetX, targetY)
    
    local absDist = math.abs(distance)
    local dirX, dirY = vec.sub(targetX, targetY, currentX, currentY)

    ---@type number
    local velX = c["velocity"][1]
    local velY = c["velocity"][2]

    if profile.linearForce then
        local fx, fy = vec.scale(dirX, dirY, profile.linearForce)
        velX, velY = vec.add(velX, velY, fx* dt, fy*dt)
    end
    if profile.constantDamp then
        velX, velY = vec.scale(velX, velY, 1.0-(profile.constantDamp*dt))
    end
    if profile.dampNearTarget then
        local locality = interp.clamp(interp.remap(absDist, 0.0, profile.dampNearTarget[1], 1.0, 0.0), 0.0, 1.0)
        locality = interp.lerp(0.0, 1.0, locality, interp.quart.into)
        local damp = 1.0-((profile.dampNearTarget[2]*dt) * locality)
        velX, velY = vec.scale(velX, velY, damp)
    end


    c["lastAccess"] = self.frame
    c["velocity"] = {velX, velY}
    c["previousTarget"] = {targetX, targetY}

    if profile.flatApproach then
        -- local fax, fay = vec.normalize(dirX, dirY)
        -- fax, fay = vec.scale(fax, fay, profile.flatApproach)
        return currentX+velX, currentY+velY
    else
        return currentX+velX, currentY+velY
    end

    -- if profile.flatApproach then
    --     local ax, ay = vec.scale(dirX, dirY, profile.flatApproach)
    --     local approach = profile.flatApproach * dt
    --     if interp.within(current+vel, towards, approach*1.3) then
    --         return towards
    --     end
    --     return current+vel+(approach*dir)
    -- else
    
    -- end
    -- return currentX, currentY
end

function Juice:clearCache(key)
    self.cache[key] = nil
end

function Juice:update()
    self.frame = self.frame + 1
end

return Juice