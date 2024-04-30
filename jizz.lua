local Object = require "dep.classic"
local interp = require "dep.interp"

---@class Jizz.PhysicsProfile
---@field flatApproach? number the value approaches every frame at this rate, on top of velocity.
---@field linearForce? number
---@field dampNearTarget? number[] [1] = how close for this to activate, [2] = multiplier
local PhysicsProfile = Object:extend()

function PhysicsProfile:new()
end



---@class Jizz : Object
---@field cache table<string, table>
---@field frame integer
---@field timeScale number
local Jizz = Object:extend()

function Jizz:new()
    self.cache = {}
    self.frame = 0
    self.timeScale = 1.0
end

---@type Jizz.PhysicsProfile
Jizz.Smoothdamp = PhysicsProfile()
-- Jizz.Smoothdamp.flatApproach = 50.0
Jizz.Smoothdamp.linearForce = 3.0
Jizz.Smoothdamp.dampNearTarget = {150.0, 5.0}
---@type Jizz.PhysicsProfile
Jizz.Tight = PhysicsProfile()
Jizz.Tight.flatApproach = 2.0
Jizz.Tight.linearForce = 8.0
Jizz.Tight.dampNearTarget = {200, 15.0}

--- Moves the number from current towards towards. 
---@param current number
---@param towards number
---@param id string
---@param profile? Jizz.PhysicsProfile
---@return number
function Jizz:number(current, towards, id, profile)
    profile = profile or Jizz.Smoothdamp
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

function Jizz:update()
    self.frame = self.frame + 1
end

return Jizz