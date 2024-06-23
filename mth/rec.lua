local obj = require "cnd.obj"

---@class cnd.mth.rec : cnd.obj
---@field x number|integer the x coordinate of the rect
---@field y number|integer the y coordinate of the rect
---@field w number|integer the width of the rect
---@field h number|integer the height of the rect
---@overload fun(x: number|integer, y: number|integer, w: number|integer, h: number|integer): cnd.mth.rec
rec = obj:extend()

function rec:new(x, y, w, h)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
end


---@param point cnd.mth.v2
---@return boolean
function rec:containsPoint(point)
    return point.x >= self.x and point.y >= self.y and point.x <= self.x+self.w and point.y <= self.y+self.h
end


return rec