local obj = require "cnd.obj"

--- Takes a texture, a position on the texture, and an inset from each edge.
--- Then it is usable as an infinitely scalable texture that wont stretch.
---@class cnd.res.ninepatch : cnd.obj
---@field source love.Image
---@field quads love.Quad[]
---@field srcW number
---@field srcH number
---@field left number
---@field top number
---@field right number
---@field bottom number
---@overload fun(image: love.Texture, srcX: number, srcY: number, srcW: number, srcH: number, left: number, top: number, right:number, bottom:number): cnd.res.ninepatch
local ninepatch = obj:extend()

function ninepatch:type() return "ninepatch" end

---comment
---@param image love.Image
---@param srcX number
---@param srcY number
---@param srcW number
---@param srcH number
---@param left integer
---@param top integer
---@param right integer
---@param bottom integer
function ninepatch:new(image, srcX, srcY, srcW, srcH, left, top, right, bottom)
    self.source = image
    self.quads = {}
    self.left = left
    self.top = top
    self.right = right
    self.bottom = bottom
    self.srcW = srcW
    self.srcH = srcH

    local imgW = image:getWidth()
    local imgH = image:getHeight()

    self.quads[1] = love.graphics.newQuad(srcX, srcY, left, top, imgW, imgH)
    self.quads[2] = love.graphics.newQuad(srcX+left, srcY, srcW-left-right, top, imgW, imgH)
    self.quads[3] = love.graphics.newQuad(srcX+srcW-right, srcY, right, top, imgW, imgH)

    self.quads[4] = love.graphics.newQuad(srcX, srcY+top, left, srcH-top-bottom, imgW, imgH)
    self.quads[5] = love.graphics.newQuad(srcX+left, srcY+top, srcW-left-right, srcH-top-bottom, imgW, imgH)
    self.quads[6] = love.graphics.newQuad(srcX+srcW-right, srcY+top, right, srcH-top-bottom, imgW, imgH)

    self.quads[7] = love.graphics.newQuad(srcX, srcY+srcH-bottom, left, bottom, imgW, imgH)
    self.quads[8] = love.graphics.newQuad(srcX+left, srcY+srcH-bottom, srcW-left-right, bottom, imgW, imgH)
    self.quads[9] = love.graphics.newQuad(srcX+srcW-right, srcY+srcH-bottom, right, bottom, imgW, imgH)
end


---@param x number x coordinate translation
---@param y number y coordinate translation
---@param w number width in pixels
---@param h number height in pixels
---@param r? number radian rotation
---@param ox? number origin x in pixels
---@param oy? number origin y in pixels
function ninepatch:draw(x, y, w, h, r, ox, oy)
    love.graphics.push()
    love.graphics.rotate(r or 0.0)
    love.graphics.translate((ox or 0.0)*-1.0, (oy or 0.0)*-1.0)
    love.graphics.translate(x, y)
    self:rawDraw(w,h)
    love.graphics.pop()
end


--- Draws without any transform logic
---@param w number width in pixels
---@param h number height in pixels
function ninepatch:rawDraw(w, h)
    local remainingWidth = w-self.left-self.right
    local remainingHeight = h-self.top-self.bottom

    local barW = remainingWidth/(self.srcW-self.left-self.right)
    local barH = remainingHeight/(self.srcH-self.top-self.bottom)

    love.graphics.draw(self.source, self.quads[1], 0.0, 0.0)
    love.graphics.draw(self.source, self.quads[2], self.left, 0.0, 0.0, barW, 1.0)
    love.graphics.draw(self.source, self.quads[3], self.left+remainingWidth, 0.0)

    love.graphics.draw(self.source, self.quads[4], 0.0, self.top, 0.0, 1.0, barH)
    love.graphics.draw(self.source, self.quads[5], self.left, self.top, 0.0, barW, barH)
    love.graphics.draw(self.source, self.quads[6], self.left+remainingWidth, self.top, 0.0, 1.0, barH)

    love.graphics.draw(self.source, self.quads[7], 0.0, self.top+remainingHeight)
    love.graphics.draw(self.source, self.quads[8], self.left, self.top+remainingHeight, 0.0, barW, 1.0)
    love.graphics.draw(self.source, self.quads[9], self.left+remainingWidth, self.top+remainingHeight)
end

return ninepatch