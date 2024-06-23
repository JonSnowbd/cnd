## What?

The ldtk module is a simple json wrap for embedded level, single world LDTK projects.

## How?

```lua
local cnd = require "cnd"
function love.load()
    -- This is just about it, its just a container of all the levels and tilesets
    -- and no further action is needed. Just look at a level, look at its layers, and do
    -- what you need to.
    local project = cnd.ldtk("content/project.ldtk")

    -- Get levels:
    local level = project:getLevel("level_001") -- The level name assigned in ldtk

    -- Get layers:
    local foregroundLayer = level:getLayer("Foreground") -- The layer name, in this case its a tile layer.

    -- You can reduce tile and auto layers to a single spritebatch for the easiest draw.
    foregroundBatch = foregroundLayer:makeSpriteBatch()

    -- You can also create collision boxes via the greedy boxes algorithm
    local intGridLayer = level:getLayer("Information")
    local colliderTileIndex = 1 -- In the intgrid, a collider tile has a value of 1

    intGridLayer:greedyBoxes(colliderTileIndex, function(rect, gridSize)
        -- your code to create a collision box:
        local inflatedBox = {
            rect[1] * gridSize,
            rect[2] * gridSize,
            rect[3] * gridSize,
            rect[4] * gridSize
        } -- Inflated from indices to actual world coordinates
    end)
end

function love.draw()
    love.graphics.draw(foregroundBatch)
end
```