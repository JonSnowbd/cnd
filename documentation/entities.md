## What?

Inside of every scene is layers, and inside of every layer is a list of entities.
Entities in Conductor are somewhat of a mix of many concepts, they perform the roles of
systems, entities, components, and events. Its a lot! But I can't wait to
show you how flexiblethe system is.

## Entity

```lua
local cnd = require "cnd"

---@type PlayerEntity : cnd.scn.entity
---@field velocity cnd.mth.v2
local PlayerEntity = cnd.scn.entity:extend()

-- Simple method to gather player input.
function PlayerEntity:input()
    self.velocity.x, self.velocity.y = 0, 0
    if love.keyboard.isDown("w") then self.velocity.y = self.velocity.y - 1 end
    if love.keyboard.isDown("a") then self.velocity.x = self.velocity.x - 1 end
    if love.keyboard.isDown("s") then self.velocity.y = self.velocity.y + 1 end
    if love.keyboard.isDown("d") then self.velocity.x = self.velocity.x + 1 end

    if self.velocity:length() > 1 then
        self.velocity = self.velocity:normalized()
    end

end

function PlayerEntity:update()
    local dt = love.timer.getDelta()

    -- Vectors have intuitive math overrides
    self.position = self.position + (self.velocity * 200.0 * dt) 
end

function PlayerEntity:draw()
    love.graphics.circle(self.position.x, self.position.y, 15.0)
end

--- This is where you should do entity construction. 
--- It is called after construction, and after being added to a layer.
---@param name string|nil Passed during construction.
function PlayerEntity:onConstruct(name)
    -- Initialize your fields
    self.velocity = cnd.mth.v2(0, 0)

    -- Every entity already has a name field declared, but we'll assign it here through construction to show it off.
    self.name = name

    -- Subscribe methods, phase will determine when it is called,
    -- and takes the function that will be called
    self:subscribe(self.parent.phase.input, PlayerEntity.input)
    self:subscribe(self.parent.phase.update, PlayerEntity.update)
end
```

And then you can create it through the scene like so

```lua
local scene = cnd.scn()
local foregroundLayer = scene:makeLayer(1000) -- Priority: higher = ran first

---@type PlayerEntity
local yourPlayer = scene:quickCreate(PlayerEntity, foregroundLayer, "Steve")
```