local obj = require "cnd.obj"

---@class cnd.mth.v2 : cnd.obj
---@field x number|integer the x coordinate of the 2d vector
---@field y number|integer the y coordinate of the 2d vector
---@overload fun(x: number|integer, y: number|integer): cnd.mth.v2
v2 = obj:extend()

function v2:new(x, y)
    self.x = x
    self.y = y
end

--- Returns the dot product of the 2 vectors.
---@param other cnd.mth.v2
---@return number dot
function v2:dot(other)
    return (self.x*other.x) + (self.y*other.y)
end

--- Returns the squared length of this vector.
---@return number lengthSquared
function v2:length2()
    return self:dot(self)
end

--- Returns the length of this vector.
---@return number length
function v2:length()
    return math.sqrt(self:length2())
end

--- Returns the squared distance between two vectors.
---@param other cnd.mth.v2
---@return number distanceSquared
function v2:distance2(other)
    return v2.length2(v2(self.x-other.x, self.y-other.y))
end

--- Returns the distance between two vectors.
---@param other cnd.mth.v2
---@return number distanceSquared
function v2:distance(other)
    return math.sqrt(self:distance(other))
end

--- Returns this vector with all the units adding up to 1.0
---@return cnd.mth.v2
function v2:normalized()
    local len = self:length()
    if len == 0.0 then return v2(0.0, 0.0) end
    return self * (1.0/len)
end

--- Returns the inbetween of two vectors, (mix*100)% along the line between them.
--- eg 0.5 = the middle point.
---@param other cnd.mth.v2
---@param mix number 0-1. Can be beyond 0-1, but typically given between the 2.
---@return cnd.mth.v2
function v2:lerp(other, mix)
    return ((other-self) * mix) + (self)
end

---@param other cnd.mth.v2|number|integer
---@return cnd.mth.v2
function v2:__add(other)
    if type(other) == "number" then
        return v2(self.x+other, self.y+other)
    end
    if other.x and other.y then
        return v2(self.x+other.x, self.y+other.y)
    end
    error("v2: attempted addition with non numerical unit: "..tostring(other))
end
---@param other cnd.mth.v2|number|integer
---@return cnd.mth.v2
function v2:__sub(other)
    if type(other) == "number" then
        return v2(self.x-other, self.y-other)
    end
    if other.x and other.y then
        return v2(self.x-other.x, self.y-other.y)
    end
    error("v2: attempted subtraction with non numerical unit: "..tostring(other))
end
---@param other cnd.mth.v2|number|integer
---@return cnd.mth.v2
function v2:__div(other)
    if type(other) == "number" then
        return v2(self.x/other, self.y/other)
    end
    if other.x and other.y then
        return v2(self.x/other.x, self.y/other.y)
    end
    error("v2: attempted division with non numerical unit: "..tostring(other))
end
---@param other cnd.mth.v2|number|integer
---@return cnd.mth.v2
function v2:__mul(other)
    if type(other) == "number" then
        return v2(self.x*other, self.y*other)
    end
    if other.x and other.y then
        return v2(self.x*other.x, self.y*other.y)
    end
    error("v2: attempted multiplication with non numerical unit: "..tostring(other))
end

return v2