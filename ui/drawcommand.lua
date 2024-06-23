local obj = require "cnd.obj"
local mth = require "cnd.mth"

---@class cnd.ui.layout.cmd
---@field target any
---@field data any
---@field color number[]
---@field position cnd.mth.v2
---@field size cnd.mth.v2
---@field debug boolean
local cmd = obj:extend()

function cmd:new(target, data, color)
    self.target = target
    self.data = data
    self.color = color or {1.0, 1.0, 1.0, 1.0}
    self.position = mth.v2(0,0)
    self.size = mth.v2(0,0)
    self.debug = false
end

---@param ui cnd.ui
function cmd:draw(ui)
    local handler = ui:getHandler(self.target)
    if handler == nil then
        error("NO HANDLE FOR "..tostring(self.target))
    end
    love.graphics.setColor(self.color[1],self.color[2],self.color[3],self.color[4])
    handler(self.target, self.data, self.position.x, self.position.y, self.size.x, self.size.y)
    if self.debug then
        love.graphics.setLineWidth(1.0)
        love.graphics.setColor(1.0, 0.0, 1.0, 1.0)
        love.graphics.rectangle("line", self.position.x, self.position.y, self.size.x, self.size.y)
    end
end

return cmd