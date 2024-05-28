local Object = require "dep.classic"
local Resource = require "dep.resource"

---@class Interface : Object
---@field resourceInstance Resource|nil
---@field juiceInstance Juice|nil
---@field juiceProfile Juice.PhysicsProfile|nil
---@field cursor number[]
---@field cursorDelta number[]
---@field horizontal number
---@field vertical number
---@field confirmState table
---@field cancelState table
---@field characterBuffer string[]
---@field renderHandler table<string, function> A lookup to handle drawing of anything custom.
---@field invalidationLifetime integer How long it takes for a context id to be freed when not used. measured in frames.
---@field currentFrame integer
---@field layoutStack Interface.Layout[]
---@field focused string|nil the full id of the widget currently focused.
---@field defaultFont love.Font|nil
local Interface = Object:extend()

Interface.Layout = require "dep.ui.layout"

function Interface:new()
    self.horizontal = 0
    self.vertical = 0
    self.confirmState = {pressed=false, held=false, released=false}
    self.cancelState = {pressed=false, held=false, released=false}
    self.characterBuffer = {}
    self.invalidationLifetime = 6
    self.currentFrame = 0
    self.renderHandler = {}
    self.layoutStack = {}
    self.cursor = {0,0}
    self.cursorDelta = {0,0}
    self.focused = nil
end

function Interface:addDefaultRenderers()
    self.renderHandler["Font"] = function(fnt, msg, x, y, w, h)
        love.graphics.setFont(fnt)
        love.graphics.print(msg, x, y)
    end
    self.renderHandler["NinePatch"] = function(val, data, x, y, w, h)
        Resource.NinePatch.draw(val, x, y, w, h)
    end
    self.renderHandler["ImageSheet"] = function(val, data, x, y, w, h)
        local t = data.type or "stretch"
        if t == "stretch" then
            local xs = w/val.tileSize[1]
            local ys = h/val.tileSize[2]
            Resource.ImageSheet.draw(val, data[1], data[2], x, y, 0, xs, ys)
        elseif t == "center" then
            local s = math.min(w/val.tileSize[1], h/val.tileSize[2])
            local leftoverX = w-(val.tileSize[1]*s)
            local leftoverY = h-(val.tileSize[2]*s)
            Resource.ImageSheet.draw(val, data[1], data[2], x+(leftoverX*0.5), y+(leftoverY*0.5), 0, s, s)
        end
    end
    self.renderHandler["Texture"] = function(val, data, x, y, w, h)
        if data then
            local xs = w/val.tileSize[1]
            local ys = h/val.tileSize[2]
            love.graphics.draw(val, data, x, y, 0, xs, ys)
        else
            local xs = w/val.tileSize[1]
            local ys = h/val.tileSize[2]
            love.graphics.draw(val, x, y, 0, xs, ys)
        end
    end
    self.renderHandler[true] = function(val, data, x, y, w, h)
        love.graphics.rectangle("fill", x, y, w, h)
    end
    self.renderHandler[false] = function(val, data, x, y, w, h)
        love.graphics.rectangle("line", x, y, w, h)
    end
end

---comment
---@param obj love.Image
---@return function|nil
function Interface:getHandler(obj)
    -- Handle literals
    if self.renderHandler[obj] then
        return self.renderHandler[obj]
    end
    if obj.type then
        return self.renderHandler[obj:type()]
    end

    -- Use the metatable as an identifier
    local meta = getmetatable(obj)
    if meta then
        return self.renderHandler[meta]
    end

    error("UI has no idea how to handle whatever it is you just passed as a render obj: "..tostring(obj))
end

function Interface:newFrame()
    self.characterBuffer = {}
end
function Interface:feedCursor(x, y, xdelta, ydelta)
    self.cursor = {x, y}
    self.cursorDelta = {xdelta, ydelta}
end
function Interface:feedConfirm(pressed, down, released)
    self.confirmState = {pressed=pressed, held=down, released=released}
end
function Interface:feedCancel(pressed, down, released)
    self.cancelState = {pressed=pressed, held=down, released=released}
end
function Interface:feedCharacter(char)
    self.characterBuffer[#self.characterBuffer+1] = char
end
---@param horizontal number magnitude on the axis. if keyboard input, pass in -1/0/1, stick axis can be fed as is.
---@param vertical number magnitude on the axis. if keyboard input, pass in -1/0/1, stick axis can be fed as is.
function Interface:feedAxis(horizontal, vertical)
    self.horizontal = horizontal
    self.vertical = vertical
end

--- Call to begin an interface element. An inventory window, player resource bars, etc.
---@param id string unique id for this window.
---@param x number
---@param y number
---@param xO number|nil origin, normalized. 0.5 = middle, 0.0 = left, 1.0 = right, default is 0.0
---@param yO number|nil origin, normalized. 0.5 = middle, 0.0 = up, 1.0 = down, default is 0.0
---@param w number|nil
---@param h number|nil
---@return Interface.Layout|nil
function Interface:start(id, x, y, xO, yO, w, h)
    local shouldCreate = false
    if self.layoutStack[id] == nil then
        shouldCreate = true
    elseif (self.currentFrame - self.layoutStack[id].requestedOn) > self.invalidationLifetime then
        shouldCreate = true
    end

    if shouldCreate then
        ---@type Interface.Layout
        local newLayout = Interface.Layout(id, self)
        self.layoutStack[id] = newLayout
        self.layoutStack[id].age = 0
    end
    self.layoutStack[id].background = nil
    self.layoutStack[id].requestedOn = self.currentFrame
    self.layoutStack[id].position = {x,y}
    self.layoutStack[id].size = {w or 0.0, h or 0.0}
    self.layoutStack[id].origin = {xO or 0.0, yO or 0.0}
    return self.layoutStack[id]
end

--- Called at the end of your update.
function Interface:update()
    for k,v in pairs(self.layoutStack) do
        if (self.currentFrame - v.requestedOn) > self.invalidationLifetime+1 then
            self.layoutStack[k] = nil
            goto continue
        end
        v:finalize(true)
        v:finalize(false)
        v.age = v.age + 1
        ::continue::
    end
    self.currentFrame = self.currentFrame + 1
end


Interface.Button = require "dep.ui.button"
Interface.Label = require "dep.ui.label"
Interface.Image = require "dep.ui.image"
Interface.Slider = require "dep.ui.slider"


function Interface:draw()
    for k,v in pairs(self.layoutStack) do
        if v.requestedOn == self.currentFrame-1 then
            v:flushDraw()
        end
    end
    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
end

return Interface