local objClass = require "cnd.obj"
local res = require "cnd.res"
local mth = require "cnd.mth"

---@class cnd.ui : cnd.obj
---@field cursor cnd.mth.v2
---@field cursorDelta cnd.mth.v2
---@field horizontal number
---@field vertical number
---@field confirmState table
---@field cancelState table
---@field characterBuffer string[]
---@field renderHandler table<string, function> A lookup to handle drawing of anything custom.
---@field invalidationLifetime integer How long it takes for a context id to be freed when not used. measured in frames.
---@field currentFrame integer
---@field layoutStack cnd.ui.layout[]
---@field focused string|nil the full id of the widget currently focused.
---@field defaultFont love.Font|nil
---@overload fun() : cnd.ui
local ui = objClass:extend()

ui.layout = require "cnd.ui.layout"

function ui:new()
    self.horizontal = 0
    self.vertical = 0
    self.confirmState = {pressed=false, held=false, released=false}
    self.cancelState = {pressed=false, held=false, released=false}
    self.characterBuffer = {}
    self.invalidationLifetime = 6
    self.currentFrame = 0
    self.renderHandler = {}
    self.layoutStack = {}
    self.cursor = mth.v2(0,0)
    self.cursorDelta = mth.v2(0,0)
    self.focused = nil
end

--- You should call this after constructing the ui, unless you know what you are
--- doing and intend on creating your own custom renderers.
function ui:addDefaultRenderers()
    self.renderHandler["Font"] = function(fnt, msg, x, y, w, h)
        love.graphics.setFont(fnt)
        love.graphics.print(msg, x, y)
    end
    self.renderHandler["ninepatch"] = function(val, data, x, y, w, h)
        res.ninepatch.draw(val, x, y, w, h)
    end
    self.renderHandler["imagesheet"] = function(val, data, x, y, w, h)
        local t = data.type or "stretch"
        if t == "stretch" then
            local xs = w/val.tileSize[1]
            local ys = h/val.tileSize[2]
            res.imagesheet.draw(val, data[1], data[2], x, y, 0, xs, ys)
        elseif t == "center" then
            local s = math.min(w/val.tileSize[1], h/val.tileSize[2])
            local leftoverX = w-(val.tileSize[1]*s)
            local leftoverY = h-(val.tileSize[2]*s)
            res.imagesheet.draw(val, data[1], data[2], x+(leftoverX*0.5), y+(leftoverY*0.5), 0, s, s)
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

---@param obj any
---@return function|nil
function ui:getHandler(obj)
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

--- Use this method to begin a new frame in the UI. Do this before
--- input and before any UI requests
function ui:newFrame()
    self.characterBuffer = {}
end
--- Use this method to feed the UI new cursor location. Do this before any
--- UI requests.
---@param position cnd.mth.v2
---@param delta cnd.mth.v2
function ui:feedCursor(position, delta)
    self.cursor = mth.v2(position.x, position.y)
    self.cursorDelta = mth.v2(delta.x, delta.y)
end
--- Use this method to feed confirm input states, in UI this is typically left click,
--- or the south/east gamepad button
---@param pressed boolean whether or not confirm is pressed
---@param down boolean whether or not confirm is down
---@param released boolean whether or not confirm is released
function ui:feedConfirm(pressed, down, released)
    self.confirmState = {pressed=pressed, held=down, released=released}
end
--- Use this method to feed cancel input states, in UI this is typically right click,
--- or the east/south gamepad button
---@param pressed boolean whether or not cancel is pressed
---@param down boolean whether or not cancel is down
---@param released boolean whether or not cancel is released
function ui:feedCancel(pressed, down, released)
    self.cancelState = {pressed=pressed, held=down, released=released}
end
--- Use this method to feed the UI raw ascii characters, which can be different
--- from other inputs from the same keys (eg uppercase v lower case)
---@param char string
function ui:feedCharacter(char)
    self.characterBuffer[#self.characterBuffer+1] = char
end
--- Use this method to feed movement input, for example left stick or the wasd cluster.
--- This is used for things like sliding a slider that is focused, or moving to new widgets.
---@param horizontal number magnitude on the axis. if keyboard input, pass in -1/0/1, stick axis can be fed as is.
---@param vertical number magnitude on the axis. if keyboard input, pass in -1/0/1, stick axis can be fed as is.
function ui:feedAxis(horizontal, vertical)
    self.horizontal = horizontal
    self.vertical = vertical
end

--- Call to begin an ui element. An inventory window, player resource bars, etc.
---@param id string unique id for this window.
---@param position cnd.mth.v2
---@param origin cnd.mth.v2|nil
---@param size cnd.mth.v2|nil
---@return cnd.ui.layout|nil
function ui:start(id, position, origin, size)
    local shouldCreate = false
    if self.layoutStack[id] == nil then
        shouldCreate = true
    elseif (self.currentFrame - self.layoutStack[id].requestedOn) > self.invalidationLifetime then
        shouldCreate = true
    end

    if shouldCreate then
        ---@type cnd.ui.layout
        local newLayout = ui.layout(id, self)
        self.layoutStack[id] = newLayout
        self.layoutStack[id].age = 0
    end
    self.layoutStack[id].background = nil
    self.layoutStack[id].requestedOn = self.currentFrame
    self.layoutStack[id].position = mth.v2(position.x, position.y)
    if size ~= nil then
        self.layoutStack[id].size = mth.v2(size.x, size.y)
    else
        self.layoutStack[id].size = mth.v2(0, 0)
    end
    if origin ~= nil then
        self.layoutStack[id].origin = mth.v2(origin.x, origin.y)
    else
        self.layoutStack[id].origin = mth.v2(0, 0)
    end
    return self.layoutStack[id]
end

--- Called at the end of your update.
function ui:update()
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


ui.button = require "cnd.ui.button"
ui.label = require "cnd.ui.label"
ui.image = require "cnd.ui.image"
ui.slider = require "cnd.ui.slider"


function ui:draw()
    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
    for k,v in pairs(self.layoutStack) do
        if v.requestedOn == self.currentFrame-1 then
            v:flushDraw()
        end
    end
    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
end

return ui