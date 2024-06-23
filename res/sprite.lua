local obj = require "cnd.obj"

---@class cnd.res.sprite : cnd.obj
---@field source love.Image
---@field quad love.Quad
---@field sourceSize number[]
---@overload fun(image: love.Texture, srcX: number, srcY: number, srcW: number, srcH: number): cnd.res.sprite
local sprite = obj:extend()

function sprite:type() return "sprite" end

---@param image love.Image
---@param srcX number
---@param srcY number
---@param srcW number
---@param srcH number
function sprite:new(image, srcX, srcY, srcW, srcH)
    self.source = image
    self.sourceSize = {srcW, srcH}
    self.quad = love.graphics.newQuad(srcX, srcY, srcW, srcH, image:getWidth(), image:getHeight())
end

---@param x number
---@param y number
---@param r number|nil
---@param sx number|nil
---@param sy number|nil
---@param ox number|nil
---@param oy number|nil
function sprite:draw(x,y,r,sx,sy,ox,oy)
    love.graphics.draw(self.source, self.quad, x, y, r or 0.0, sx or 1.0, sy or 1.0, ox or 0.0, oy or 0.0)
end

return sprite