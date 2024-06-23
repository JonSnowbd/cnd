## What?

Cnd is the overall package that contains everything. It has a few things expected to be ran
on your end to function properly, but otherwise is mostly a bunch of classes for you to use and extend.

It decides a lot for you, so I consider it very opinionated in terms of Lua frameworks.
Cnd has a lot included, so if you need more from the framework hit me up with an issue
and I'll consider adding a solution to the framework.

## How?

```lua
local cnd = require "cnd" -- require cnd

function love.load()
    cnd.currentscn = YourSceneType() -- Load a scene (or dont, its not immediately needed)
end

function love.update()
    -- Updates the current scene, so consider this the entrypoint
    -- for your whole games update call
    cnd.update()
end

function love.draw()
    -- Draws the current scene, same as update, but with the draw life cycle
    cnd.draw()
end
```

And from there your logic should be encapsulated inside of scenes and entities.