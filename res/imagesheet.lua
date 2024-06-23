local obj = require "cnd.obj"

--- A type of image, takes the size of the 'tiles' of a sheet and lets you draw each
--- sprite on the atlas with indices.
---@class cnd.res.imagesheet : cnd.obj
---@field source love.Image
---@field quads love.Quad[][]
---@field tileSize number[]
---@overload fun(image: love.Texture, tileW: number, tileH: number): cnd.res.imagesheet
local imagesheet = obj:extend()

function imagesheet:new(image, tileWidth, tileHeight)
    self.source = image
    self.quads = {}
    self.tileSize = {tileWidth, tileHeight}
    for y=1,math.floor(self.source:getHeight()/tileHeight) do
        self.quads[y] = {}
        for x=1,math.floor(self.source:getWidth()/tileWidth) do
            self.quads[y][x] = love.graphics.newQuad((x-1)*tileWidth, (y-1)*tileHeight, tileWidth, tileHeight, self.source:getWidth(), self.source:getHeight())
        end
    end
end

---@param xsprite integer the x index of the sprite, starting with 1
---@param ysprite integer the y index of the sprite, starting with 1
---@param x number|nil x coordinate translation
---@param y number|nil y coordinate translation
---@param r number|nil radian rotation
---@param xs number|nil x scale
---@param ys number|nil y scale
---@param ox number|nil origin x in pixels
---@param oy number|nil origin y in pixels
function imagesheet:draw(xsprite, ysprite, x, y, r, xs, ys, ox, oy)
    love.graphics.draw(self.source, self.quads[ysprite][xsprite], x or 0.0, y or 0.0, r or 0.0, xs or 1.0, ys or 1.0, ox or 0.0, oy or 0.0)
end

function imagesheet:type() return "imagesheet" end

return imagesheet