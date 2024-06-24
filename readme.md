# What?

CND (Conductor) is an all in one library that provides a very opinionated interface for creating games.
Inside you will find that CND provides you with:

- Graphics and screen management suited for 2d pixel games (low res render target)
- Scene system with an approach to logic that provides a lot of freedom and organization
- Bundled and integrated libraries, the best that Love2D/Lua authors have to offer
- - [json.lua](https://github.com/rxi/json.lua)
- - [baton](https://github.com/tesselode/baton)
- - [classic](https://github.com/rxi/classic)
- Convenient math library with interpolation methods.
- Fully typed and documented (Please use [sumneko](https://github.com/LuaLS/lua-language-server) for best experience!)
- UI system with complete styling flexibility and basic functions. 

## Is Conductor for me?

I did mention earlier that Conductor is pretty opinionated, I will list the things that using Conductor will
do for you. If any of these items conflict with what you want to do, or Conductor does them in a way you do not
want, I recommend looking at the other great libraries that Love2D has to offer.

- Conductor handles the entirety of the screen drawing process. Render targets are filled by you and then conductor will spread
them onto the screen and handle everything related to that, including translating the mouse coordinates and handling the 2d camera.
- Conductor assumes you will be using its Scene system. It is incredibly flexible but is integrated enough with the screen stuff in the first
point that I recommend not doing anything outside of the scene system. I guarantee you, you can do anything with the scene system! (If you choose to not
use the scene system, but will use the screen system, look at how the scene will operate the scr methods in update and draw!)
- All of Conductor's pieces rely on Conductor types. If being locked into my vector and resource types is not what you want, or do not want duplicate
classes for math things you already have, I recommend looking elsewhere!
(Note this does not mean Conductor is not extensible, you are free to add more types, or modify Conductor's source code to suit you.)
- Conductor handles rendering by drawing into a smaller RT and then blowing it up to the screen, this is predominantly aimed at pixel art games in this regard.

## Whats with the shortened names?

I wanted my library to be very terse and not lead to long lines when calling many of the functions.
Personally I find them to be intuitive after a bit of working with them, heres the expanded names:

- cnd = Conductor
- cnd.mth = Conductor.Math
- cnd.obj = Conductor.Object
- cnd.arr = Conductor.Array
- cnd.scn = Conductor.Scene
- cnd.scr = Conductor.Screen
- cnd.res = Conductor.Resources

## Whats the general approach for a cnd game?

For a smooth start I recommend:

1) creating a global for your screen instance, feeding it into `cnd.scn.defaultScreen`, and creating however
many extensions of `cnd.scn` that creates entities for each type of scene you need, eg `MainMenuScene`, `OptionsScene`
2) (optional) creating a global for your games input, via `cnd.input`. This does not need to be plugged anywhere, but is incredibly
useful for every file related to gameplay.
3) (optional) creating a global for your games assets, taking care to use `cnd.res` types where it would be helpful.
 This will give you 
3) assigning your scene to `cnd.currentscn`, and adding `cnd.update` and `cnd.draw` into your love loop functions.
4) now your game's logic is contained entirely in these entities and scenes.

## Example

```lua
local cnd = require "cnd"

-- --
-- ENTITY CREATION
-- --

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

-- --
-- LOVE CALLBACKS
-- --

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
    cnd.update()
    collectgarbage("step", 100)
end

function love.draw()
    cnd.draw()
end
```

## Install

Simply `git clone github.com/jonsnowbd/cnd` in your project, next to `main.lua` so your project structure looks like:

```
<DIRECTORY>
--> cnd/
------> init.lua
------> (other files)
--> main.lua
```

And from there you can `local cnd = require "cnd"` to use all that Conductor has to offer.

## Getting started

After installing, if you want you could just use the utilities found under `cnd` such as the math library,
pathfinding library, etc, however I recommend using Conductor in its entirety.

To use Conductor for your game, create a screen graphics manager, give it to `cnd.scn.defaultScr` and then
use the life cycle methods in the love callbacks.

```lua
local cnd = require "cnd"

function love.load()
    scr = cnd.scr(640, 360)
    cnd.scn.defaultScr = scr
end

function love.update()
    cnd:update()
end

function love.draw()
    cnd:draw()
end
```

From there cnd will update and draw the current scene as determined by `cnd.currentscn`