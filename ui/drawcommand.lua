local Object = require "dep.classic"

---@class Interface.Layout.DrawCommand
---@field target any
---@field data any
---@field color number[]
---@field position number[]
---@field size number[]
---@field debug boolean
local DrawCommand = Object:extend()

function DrawCommand:new(target, data, color)
    self.target = target
    self.data = data
    self.color = color or {1.0, 1.0, 1.0, 1.0}
    self.position = {0,0}
    self.size = {0,0}
    self.debug = false
end

---@param ui Interface
function DrawCommand:draw(ui)
    local handler = ui:getHandler(self.target)
    if handler == nil then
        error("NO HANDLE FOR "..tostring(self.target))
    end
    love.graphics.setColor(self.color[1],self.color[2],self.color[3],self.color[4])
    handler(self.target, self.data, self.position[1], self.position[2], self.size[1], self.size[2])
    if self.debug then
        love.graphics.setLineWidth(1.0)
        love.graphics.setColor(1.0, 0.0, 1.0, 1.0)
        love.graphics.rectangle("line", self.position[1], self.position[2], self.size[1], self.size[2])
    end
end

return DrawCommand