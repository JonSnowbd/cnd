local vec = {}


---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
---@return number
vec.sub = function(x1, y1, x2, y2)
    return x1-x2, y1-y2
end
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
---@return number
vec.add = function(x1, y1, x2, y2)
    return x1+x2, y1+y2
end
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
---@return number
vec.div = function(x1, y1, x2, y2)
    return x1/x2, y1/y2
end
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
---@return number
vec.mult = function(x1, y1, x2, y2)
    return x1*x2, y1*y2
end
--- Scales the whole vector by a number.
---@param x number
---@param y number
---@param scalar number
---@return number X
---@return number Y
vec.scale = function(x, y, scalar)
    return x*scalar, y*scalar
end
--- Divides the whole vector by a number.
---@param x number
---@param y number
---@param divScale number
---@return number X
---@return number Y
vec.scaleDiv = function(x, y, divScale)
    return x/divScale, y/divScale
end
--- Returns the dot product of the 2 vectors.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number dot
vec.dot = function(x1, y1, x2, y2)
    return (x1*x2) + (y1*y2)
end

--- Returns the squared length of the vector
---@param x number
---@param y number
---@return number lengthSquared
vec.length2 = function(x, y)
    local dot = vec.dot(x, y, x, y)
    return dot
end
--- Returns the length of the vector
---@param x number
---@param y number
---@return number length
vec.length = function(x, y)
    return math.sqrt(vec.length2(x,y))
end

--- Returns the squared distance between the two vectors.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number squaredDistance
vec.distance2 = function(x1, y1, x2, y2)
    return vec.length2(x1-x2, y1-y2)
end
--- Returns the distance between the two vectors.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number distance
vec.distance = function(x1, y1, x2, y2)
    return math.sqrt(vec.distance2(x1, y1, x2, y2))
end

--- Returns the vector with its length as 1.0
---@param x number
---@param y number
---@return number
---@return number
vec.normalize = function(x, y)
    local len = vec.length(x,y)
    if len == 0.0 then return 0, 0 end
    return vec.scale(x, y, 1.0/len)
end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param mix number
---@return number X
---@return number Y
vec.lerp = function(x1, y1, x2, y2, mix)
    local x,y = vec.sub(x2,y2, x1,y1)
    x,y = vec.scale(x,y, mix)
    x,y = vec.add(x1,x2, x,y)
    return x, y
end

--- Floors each axis
---@param x number
---@param y number
---@return integer
---@return integer
vec.floored = function(x, y)
    return math.floor(x), math.floor(y)
end

return vec