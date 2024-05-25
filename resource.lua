local Object = require "dep.classic"
local json = require "dep.json"

---@class Resource.ImageSheet : Object
---@field source love.Image
---@field quads love.Quad[][]
---@field tileSize number[]
---@overload fun(image: love.Texture, tileW: number, tileH: number): Resource.ImageSheet
local ImageSheet = Object:extend()

function ImageSheet:new(image, tileWidth, tileHeight)
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

---comment
---@param xSprite integer the x index of the sprite, starting with 1
---@param ySprite integer the y index of the sprite, starting with 1
---@param x? number x coordinate translation
---@param y? number y coordinate translation
---@param r? number radian rotation
---@param xs? number x scale
---@param ys? number y scale
---@param ox? number origin x in pixels
---@param oy? number origin y in pixels
function ImageSheet:draw(xSprite, ySprite, x, y, r, xs, ys, ox, oy)
    love.graphics.draw(self.source, self.quads[ySprite][xSprite], x or 0.0, y or 0.0, r or 0.0, xs or 1.0, ys or 1.0, ox or 0.0, oy or 0.0)
end

function ImageSheet:type() return "ImageSheet" end


---@class Resource.Sprite : Object
---@field source love.Image
---@field quad love.Quad
---@overload fun(image: love.Texture, srcX: number, srcY: number, srcW: number, srcH: number): Resource.Sprite
local Sprite = Object:extend()

function Sprite:type() return "Sprite" end

---@param image love.Image
---@param srcX number
---@param srcY number
---@param srcW number
---@param srcH number
function Sprite:new(image, srcX, srcY, srcW, srcH)
    self.source = image
    self.quad = love.graphics.newQuad(srcX, srcY, srcW, srcH, image:getWidth(), image:getHeight())
end

---@param x number
---@param y number
---@param r number|nil
---@param sx number|nil
---@param sy number|nil
---@param ox number|nil
---@param oy number|nil
function Sprite:draw(x,y,r,sx,sy,ox,oy)
    love.graphics.draw(self.source, self.quad, x, y, r or 0.0, sx or 1.0, sy or 1.0, ox or 0.0, oy or 0.0)
end

---@class Resource.NinePatch : Object
---@field source love.Image
---@field quads love.Quad[]
---@field srcW number
---@field srcH number
---@field left number
---@field top number
---@field right number
---@field bottom number
---@overload fun(image: love.Texture, srcX: number, srcY: number, srcW: number, srcH: number, left: number, top: number, right:number, bottom:number): Resource.NinePatch
local NinePatch = Object:extend()

function NinePatch:type() return "NinePatch" end

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
function NinePatch:new(image, srcX, srcY, srcW, srcH, left, top, right, bottom)
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
function NinePatch:draw(x, y, w, h, r, ox, oy)
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
function NinePatch:rawDraw(w, h)
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

---@class Resource : Object
---@field identity string
---@overload fun(identity: string): Resource
local Resource = Object:extend()

Resource.ImageSheet = ImageSheet
Resource.NinePatch = NinePatch
Resource.Sprite = Sprite

function Resource:new(identity)
    love.filesystem.setIdentity(identity)
    self.identity = identity
end

local dirOf = function(filePath)
    return filePath:match("(.*/)")
end

--- Saves data to a path in the save directory, overwriting if exists.
---@param userPath string name of the file in the save directory, eg "settings/player1"
---@param data table pass in the default settings of the resource, this wont be returned if the file exists.
---@param tight boolean if true, compresses.
function Resource:save(userPath, data, tight)
    local dir = dirOf(userPath)
    if dir ~= nil and dir ~= "" then
        love.filesystem.createDirectory(dir)
    end
    if tight then
        local data = love.data.compress("string", "gzip", json.encode(data))
        love.filesystem.write(userPath, data)
    else
        local data = json.encode(data)
        love.filesystem.write(userPath, data)
    end
    print("DEP: Saving '"..userPath.."'")
end
--- Looks in save directory for the path, and loads it to return as a table,
--- or returns defaultData after persisting the default data to the userPath if it didnt exist.
---@param userPath string name of the file in the save directory, eg "settings/player1"
---@param defaultData table pass in the default settings of the resource, this wont be returned if the file exists.
---@param tight boolean if true, decompresses data.
---@return table
function Resource:load(userPath, defaultData, tight)
    local exists = love.filesystem.getInfo(userPath, "file") ~= nil
    if exists then
        local data = love.filesystem.read(userPath)
        if tight then
            ---@diagnostic disable-next-line: cast-local-type
            data = love.data.decompress("string", "gzip", data)
        end
        print("DEP: Loading from file '"..userPath.."'")
        return json.decode(data)
    else
        Resource:sync(userPath, defaultData, tight)
        return defaultData
    end
end

return Resource