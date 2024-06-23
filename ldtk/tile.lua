local obj = require "cnd.obj"
local mth = require "cnd.mth"

---@class cnd.ldtk.tile
---@field position cnd.mth.v2 pixel position in layer space
---@field src cnd.mth.v2 src position in pixels
---@field alpha number transparency, 0.0 = invisibile, 1.0 = fully visible
---@overload fun(object: table): cnd.ldtk.tile
local tile = obj:extend()

function tile:new(object)
    self.position = mth.v2(object["px"][1], object["px"][2])
    self.src = mth.v2(object["src"][1], object["src"][2])
    self.alpha = object["a"]
    -- TODO flip bits
end

return tile