```lua
local cnd = require "cnd"

-- ENTITY CREATION

---@class PlayerEntity : cnd.scn.entity
---@field vel cnd.mth.v2 Velocity of the player.
local PlayerEntity = cnd.scn.entity:extend()

function PlayerEntity:update()
    self.vel = cnd.mth.v2(0, 0)
    if love.keyboard.isDown("w") then self.vel.y =  self.vel.y - 1.0 end
    if love.keyboard.isDown("s") then self.vel.y =  self.vel.y + 1.0 end
    if love.keyboard.isDown("a") then self.vel.x =  self.vel.x - 1.0 end
    if love.keyboard.isDown("d") then self.vel.x =  self.vel.x + 1.0 end

    local dt = love.timer.getDelta()

    self.position = self.position + (self.vel:normalized() * 100.0 * dt)
end

function PlayerEntity:draw()
    love.graphics.circle("fill", self.position.x, self.position.y, 10.0)
end

function PlayerEntity:onConstruct(...)
    self.vel = cnd.mth.v2(0.0, 0.0)

    -- Hook into as many phases as needed, and listen for events
    -- The functions passed will be given the entity, and data of each phase or event.
    self:subscribe(cnd.scn.phase.update, PlayerEntity.update)
    self:subscribe(cnd.scn.phase.draw, PlayerEntity.draw)
end

-- LOVE CALLBACKS

function love.load()
    scr = cnd.scr(640, 360)
    cnd.scn.defaultScr = scr

    -- Scene creation
    local s = cnd.scn()
    local main = s:makeLayer(900)

    s:quickCreate(PlayerEntity, main)

    local layer = s:getLayer(main)
    layer.space = "world"

    cnd.currentscn = s
end

function love.update()
    cnd:update()
    collectgarbage("step", 100)
end

function love.draw()
    cnd:draw()
end
```