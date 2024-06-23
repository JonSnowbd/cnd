local cnd = {
    --- json.lua, used for encoding and decoding lua tables to and from json.
    json = require "cnd.json",
    --- Classic.lua, the base object for everything.
    obj = require "cnd.obj",
    --- A simple wrap over a table that provides array-like features.
    arr = require "cnd.arr",
    --- All things math.
    mth = require "cnd.mth",
    --- A full scene system with entities.
    scn = require "cnd.scn",
    --- A screen/graphics manager that blows up a low res render target over the screen.
    scr = require "cnd.scr",
    --- Load and use LDTK Project files
    ldtk = require "cnd.ldtk",
    --- Handle saving, loading, and bonus type for rendering.
    res = require "cnd.res",
    --- Inlined Baton dependency, great for input
    input = require "cnd.baton",
    --- Minimally featured immediate gui with persistent state, and incredibly powerful widget creation
    ui = require "cnd.ui",
    ---@type cnd.scn|nil
    currentscn = nil,
}

function cnd.update()
    if cnd.currentscn ~= nil then
        cnd.currentscn:update()
    end
end

function cnd.draw()
    if cnd.currentscn ~= nil then
        cnd.currentscn:draw()
    end
end

return cnd