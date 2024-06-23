## What?

Input in Conductor is just an inlined, modified [baton.lua](https://github.com/tesselode/baton).
I recommend using it as a global created in your main, or as an entity in the scene with service locator events.

## How

```lua
function love.load()
    controls = cnd.input.new({
        controls = {
            interact = {"mouse:1", "button:a"},
            mouseDrag = {"mouse:2"},
            camUp = {"key:up", "axis:lefty-"},
            camDown = {"key:down", "axis:lefty+"},
            camLeft = {"key:left", "axis:leftx-"},
            camRight = {"key:right", "axis:leftx+"},
        },
        pairs = {
            camMove = {"camLeft", "camRight", "camUp", "camDown"}
        },
        joystick = love.joystick.getJoysticks()[1]
    })

    -- and then you can use it pretty nicely:
    local dragging = controls:down("mouseDrag") -- also: pressed, released
    local x,y = controls:get("camMove")
end
```