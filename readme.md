# Dep

A personal toolkit for love2d development.
Covers abstractions for:

1) Interpolation and basic maths in `dep.interp`
2) Json and classic libraries prepackaged in `dep.json` and `dep.classic`
3) LDtk project parsing, with love integration in `dep.ldtk`
4) Resource manager that handles persisting/updating/loading conveniently in `dep.resource`
5) Translation support with $TAG support in `dep.translate` (inserts globals, simply require it without assignment)
6) Complete handling of efficient low-res virtual viewports in `dep.playground`

and a focus on:

1) Complete compatibility with base love2d. None of the functions interfere with your love2d settings,
if any use a love2d system such as transform, it is gracefully handled via bind/unbind pairs that will
restore your settings.
2) Footgun level convenience that befits a solo dev.. But made manageable with full typehints. Manage global state
cleanly with the Lua language server giving you full clarity in your files.
3) Everything out of the box, but implemented with the box. No magic in the assets, its all put together with the same
tools you have from dep.

## dep.resource

To use:

```lua
local Resource = require "dep.resource"
function love.load()
    ---@type Resource
    RS = Resource()
    -- Automatically loads
    SETTINGS = RS:load("user/settings.json", {name = "Bob", points = 10.0}, false)

    -- If user/settings.json didnt exist:
    print(SETTINGS["name"]) -- Bob
    -- If it did, and was changed to Peter:
    print(SETTINGS["name"]) -- Peter
end

function love.quit()
    -- Then just resync on exit, also sync once in a while to have an autosave
    -- in case of crash.
    RS:sync("user/settings.json", SETTINGS, false)
end
```

## dep.translate

Introduces two global functions `SET_TRANSLATION` and `TR`

#### content/en.lua
```lua
return {
    welcomeMessage = "Hello $NAME!",
}
```
#### usage
```lua
require "dep.translate"
function love.load()
    local locale = "en"

    -- Compiles all the lua tables into one for all subsequent calls of TR.
    -- Restarting not required, simply call this again and the table will be
    -- remade.
    SET_TRANSLATION({
        "dep/defaultTranslation/"..locale..".lua",
        "content/"..locale..".lua"
    })

    print(TR("welcomeMessage", {NAME = "John"}))

end
```

## dep.playground

```lua
local Playground = require "dep.playground"
function love.load()
    ---@type Playground
    PG = Playground(800, 600)

    -- For pixel plus finishing shader, linear is needed
    PG.gameCanvas:setFilter("linear", "linear")
    love.graphics.setFont(PG.debugFont)

end

function love.update(dt)
    PG:update()
end

function love.draw()
    PG:bind()
    PG:enableCamera()
    -- Draw world stuff here, it will be drawn to the internal 800x600 rt in world space.
    PG:disableCamera()
    -- Draw your screen stuff here, it will be drawn to the internal 800x600 rt
    PG:unbind()
    PG:draw("pixelPlus", {sharpness = 4.0})
end
```