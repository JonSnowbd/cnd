local mth = {}

mth.interp = require "cnd.mth.interp"
mth.v2 = require "cnd.mth.v2"
mth.rec = require "cnd.mth.rec"

--- -1 if < 0, 1 if > 0, 0 if 0
---@param value number
function mth.sign(value)
    if value > 0 then return 1 end
    if value < 0 then return -1 end
    return 0
end

--- Clamps a number between min and max
---@param val number
---@param min number
---@param max number
---@return number
mth.clamp = function(val, min, max)
    if val < min then
        return min
    elseif val > max then
        return max
    end

    return val
end

---snaps a number to the nearest increment of `to`
---@param n number current value
---@param to number
---@return number
mth.snap = function(n, to)
    return math.floor(n/to + 0.5) * to
end

mth.atan = math.atan
mth.atan2 = math.atan2
mth.ceil = math.ceil
mth.cos = math.cos
mth.cosh = math.cosh
mth.deg = math.deg
mth.abs = math.abs
mth.acos = math.acos
mth.asin = math.asin
mth.exp = math.exp
mth.floor = math.floor
mth.fmod = math.fmod
mth.frexp = math.frexp
mth.log = math.log
mth.max = math.max
mth.min = math.min
mth.pow = math.pow
mth.rad = math.rad
mth.random = math.random
mth.sin = math.sin
mth.sinh = math.sinh
mth.sqrt = math.sqrt
mth.tan = math.tan
mth.tanh = math.tanh
mth.ult = math.ult


return mth