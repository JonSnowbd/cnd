local pow, sin, cos, pi, sqrt, abs, asin = math.pow, math.sin, math.cos, math.pi, math.sqrt, math.abs, math.asin
local calculatePAS = function(p,a,c,d)
    p, a = p or d * 0.3, a or 0
    if a < abs(c) then return p, c, p / 4 end -- p, a, s
    return p, a, p / (2 * pi) * asin(c/a) -- p,a,s
end

local interp = {}

--- Clamps a number between min and max
---@param val number
---@param min number
---@param max number
---@return number
interp.clamp = function(val, min, max)
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
interp.snap = function(n, to)
    return math.floor(n/to + 0.5) * to
end

--- takes a value, and the expected range it will be given in, and then
--- outputs the output range within the ratio that the value was inside the value range...
--- its complicated but its just lerp on steroids.
---@param value number the value
---@param valueRangeStart number the value's context start
---@param valueRangeEnd number the value's context end
---@param outputRangeStart number the output's remapped start
---@param outputRangeEnd number the output's remapped end
---@return number
interp.remap = function(value, valueRangeStart, valueRangeEnd, outputRangeStart, outputRangeEnd)
    return outputRangeStart+(value-valueRangeStart)*(outputRangeEnd-outputRangeStart)/(valueRangeEnd-valueRangeStart)
end

---@param from number the start of the range
---@param to number the end of the range
---@param mix number a number usually between 0.0 and 1.0, where 0.0 results in `from` and 1.0 results in `to`
---@param fn? function = the interpolation, eg interp.quad.inOut. if nil, is a simple linear interp
---@return number
interp.lerp = function(from,to,mix,fn)
    if fn then
        return fn(mix, from, to-from, 1.0)
    end
    return from * (1-mix) + to * mix
end


--- returns true if the value falls on or between `target-delta` and `target+delta `
---@param value number
---@param delta number
---@return boolean
interp.within = function(value, target, delta)
    return value >= target-delta and value <= target+delta
end

---@param v number
---@return integer
interp.sign = function(v)
    if v > 0.0 then
        return 1
    elseif v < 0.0 then
        return -1
    end
    return 0
end

---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.linear = function(t, b, c, d)
    return c * t / d + b
end

interp.quad = {}
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.quad.into = function(t, b, c, d)
    return c * pow(t / d, 2) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.quad.out = function(t, b, c, d)
    t = t / d
    return -c * t * (t - 2) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.quad.inOut = function(t, b, c, d)
    t = t / d * 2
    if t < 1 then return c / 2 * pow(t, 2) + b end
    return -c / 2 * ((t - 1) * (t - 3) - 1) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.quad.outIn = function(t, b, c, d)
    if t < d / 2 then return interp.quad.out(t * 2, b, c / 2, d) end
    return interp.quad.into((t * 2) - d, b + c / 2, c / 2, d)
end

interp.cubic = {}
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.cubic.into  = function(t, b, c, d)
    return c * pow(t / d, 3) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.cubic.out = function(t, b, c, d)
    return c * (pow(t / d - 1, 3) + 1) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.cubic.inOut = function(t, b, c, d)
    t = t / d * 2
    if t < 1 then return c / 2 * t * t * t + b end
    t = t - 2
    return c / 2 * (t * t * t + 2) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.cubic.outIn = function(t, b, c, d)
    if t < d / 2 then return interp.cubic.out(t * 2, b, c / 2, d) end
    return interp.cubic.into((t * 2) - d, b + c / 2, c / 2, d)
end


interp.quart = {}
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.quart.into = function(t, b, c, d)
    return c * pow(t / d, 4) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.quart.out = function(t, b, c, d)
    return -c * (pow(t / d - 1, 4) - 1) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.quart.inOut = function(t, b, c, d)
    t = t / d * 2
    if t < 1 then return c / 2 * pow(t, 4) + b end
    return -c / 2 * (pow(t - 2, 4) - 2) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.quart.outIn = function(t, b, c, d)
    if t < d / 2 then return interp.quart.out(t * 2, b, c / 2, d) end
    return interp.quart.into((t * 2) - d, b + c / 2, c / 2, d)
end


interp.quint = {}
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.quint.into = function(t, b, c, d)
    return c * pow(t / d, 5) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.quint.out = function(t, b, c, d)
    return c * (pow(t / d - 1, 5) + 1) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.quint.inOut = function(t, b, c, d)
    t = t / d * 2
    if t < 1 then return c / 2 * pow(t, 5) + b end
    return c / 2 * (pow(t - 2, 5) + 2) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.quint.outIn = function(t, b, c, d)
    if t < d / 2 then return interp.quint.out(t * 2, b, c / 2, d) end
    return interp.quint.into((t * 2) - d, b + c / 2, c / 2, d)
end


interp.sine = {}
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.sine.into = function(t, b, c, d)
    return -c * cos(t / d * (pi / 2)) + c + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.sine.out = function(t, b, c, d)
    return c * sin(t / d * (pi / 2)) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.sine.inOut = function(t, b, c, d)
    return -c / 2 * (cos(pi * t / d) - 1) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.sine.outIn = function(t, b, c, d)
    if t < d / 2 then return interp.sine.out(t * 2, b, c / 2, d) end
    return interp.sine.into((t * 2) -d, b + c / 2, c / 2, d)
end

interp.expo = {}
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.expo.into = function(t, b, c, d)
    if t == 0 then return b end
    return c * pow(2, 10 * (t / d - 1)) + b - c * 0.001
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.expo.out = function(t, b, c, d)
    if t == d then return b + c end
    return c * 1.001 * (-pow(2, -10 * t / d) + 1) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.expo.inOut = function(t, b, c, d)
    if t == 0 then return b end
    if t == d then return b + c end
    t = t / d * 2
    if t < 1 then return c / 2 * pow(2, 10 * (t - 1)) + b - c * 0.0005 end
    return c / 2 * 1.0005 * (-pow(2, -10 * (t - 1)) + 2) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.expo.outIn = function(t, b, c, d)
    if t < d / 2 then return interp.expo.out(t * 2, b, c / 2, d) end
    return interp.expo.into((t * 2) - d, b + c / 2, c / 2, d)
end

interp.circ = {}
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.circ.into = function(t, b, c, d)
    return(-c * (sqrt(1 - pow(t / d, 2)) - 1) + b)
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.circ.out = function(t, b, c, d)
    return(c * sqrt(1 - pow(t / d - 1, 2)) + b)
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.circ.inOut = function(t, b, c, d)
    t = t / d * 2
    if t < 1 then return -c / 2 * (sqrt(1 - t * t) - 1) + b end
    t = t - 2
    return c / 2 * (sqrt(1 - t * t) + 1) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.circ.outIn = function(t, b, c, d)
    if t < d / 2 then return interp.circ.out(t * 2, b, c / 2, d) end
    return interp.circ.into((t * 2) - d, b + c / 2, c / 2, d)
end

interp.elastic = {}
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@param a number the amplitude of the elastic motion
---@param p number the period of the elastic motion
---@return number
interp.elastic.into = function(t, b, c, d, a, p)
    local s
    if t == 0 then return b end
    t = t / d
    if t == 1  then return b + c end
    p,a,s = calculatePAS(p,a,c,d)
    t = t - 1
    return -(a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@param a number the amplitude of the elastic motion
---@param p number the period of the elastic motion
---@return number
interp.elastic.out = function(t, b, c, d, a, p)
    local s
    if t == 0 then return b end
    t = t / d
    if t == 1 then return b + c end
    p,a,s = calculatePAS(p,a,c,d)
    return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p) + c + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@param a number the amplitude of the elastic motion
---@param p number the period of the elastic motion
---@return number
interp.elastic.inOut = function(t, b, c, d, a, p)
    local s
    if t == 0 then return b end
    t = t / d * 2
    if t == 2 then return b + c end
    p,a,s = calculatePAS(p,a,c,d)
    t = t - 1
    if t < 0 then return -0.5 * (a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b end
    return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p ) * 0.5 + c + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@param a number the amplitude of the elastic motion
---@param p number the period of the elastic motion
---@return number
interp.elastic.outIn = function(t, b, c, d, a, p)
    if t < d / 2 then return interp.elastic.out(t * 2, b, c / 2, d, a, p) end
    return interp.elastic.into((t * 2) - d, b + c / 2, c / 2, d, a, p)
end

interp.back = {}
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@param s number how much over/undershoot
---@return number
interp.back.into = function(t, b, c, d, s)
    s = s or 1.70158
    t = t / d
    return c * t * t * ((s + 1) * t - s) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing
---@param s number how much over/undershoot
---@return number
interp.back.out = function(t, b, c, d, s)
    s = s or 1.70158
    t = t / d - 1
    return c * (t * t * ((s + 1) * t + s) + 1) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@param s number how much over/undershoot
---@return number
interp.back.inOut = function(t, b, c, d, s)
    s = (s or 1.70158) * 1.525
    t = t / d * 2
    if t < 1 then return c / 2 * (t * t * ((s + 1) * t - s)) + b end
    t = t - 2
    return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@param s number how much over/undershoot
---@return number
interp.back.outIn = function(t, b, c, d, s)
    if t < d / 2 then return interp.back.out(t * 2, b, c / 2, d, s) end
    return interp.back.into((t * 2) - d, b + c / 2, c / 2, d, s)
end

interp.bounce = {}
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.bounce.out = function(t, b, c, d)
    t = t / d
    if t < 1 / 2.75 then return c * (7.5625 * t * t) + b end
    if t < 2 / 2.75 then
        t = t - (1.5 / 2.75)
        return c * (7.5625 * t * t + 0.75) + b
    elseif t < 2.5 / 2.75 then
        t = t - (2.25 / 2.75)
        return c * (7.5625 * t * t + 0.9375) + b
    end
    t = t - (2.625 / 2.75)
    return c * (7.5625 * t * t + 0.984375) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.bounce.into = function(t, b, c, d)
    return c - interp.bounce.out(d - t, 0, c, d) + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.bounce.inOut = function(t, b, c, d)
    if t < d / 2 then return interp.bounce.into(t * 2, 0, c, d) * 0.5 + b end
    return interp.bounce.out(t * 2 - d, 0, c, d) * 0.5 + c * .5 + b
end
---@param t number the current time that has passed since the easings beginning.
---@param b number the starting value
---@param c number how much the starting value will change over the duration
---@param d number the total duration of the easing.
---@return number
interp.bounce.outIn = function(t, b, c, d)
    if t < d / 2 then return interp.bounce.out(t * 2, b, c / 2, d) end
    return interp.bounce.into((t * 2) - d, b + c / 2, c / 2, d)
end

return interp