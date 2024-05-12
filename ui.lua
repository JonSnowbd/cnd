local Object = require "dep.classic"

---@class Interface.Layout.DrawCommand
---@field target any
---@field data any
---@field color number[]
---@field position number[]
---@field size number[]
local DrawCommand = Object:extend()

function DrawCommand:new(target, data, color)
    self.target = target
    self.data = data
    self.color = color or {1.0, 1.0, 1.0, 1.0}
    self.position = {0,0}
    self.size = {0,0}
end

---@param ui Interface
function DrawCommand:draw(ui)
    print("requesting")
    local handler = ui:getHandler(self.target)
    if handler == nil then
        error("NO HANDLE FOR "..tostring(self.target))
    end
    love.graphics.setColor(self.color[1],self.color[2],self.color[3],self.color[4])
    handler(self.target, self.data, self.position[1], self.position[2], self.size[1], self.size[2])
end

---@class Interface.Layout
---@field id string
---@field parent Interface
---@field background Interface.Layout.DrawCommand|nil
---@field position number[]
---@field size number[]|nil
---@field origin number[]
---@field draws Interface.Layout.DrawCommand[]
---@field splat number[]
---@field remainingSpace number[]
---@field requestedOn integer
---@field widgets table<string,table>
---@field widgetOrder string[]
local Layout = Object:extend()

Layout.DrawCommand = DrawCommand

function Layout:new(id, parent)
    self.id = id
    self.parent = parent
    self.position = {0,0}
    self.size = {0,0}
    self.origin = {0,0}
    self.draws = {}
    self.splat = {0,0,0,0}
    self.remainingSpace = {0,0}
    self.requestedOn = parent.currentFrame
    self.widgets = {}
    self.widgetOrder = {}
end

function Layout:widgetIsHovered(id)
    return false
end
function Layout:widgetIsFocused(id)
    return false
end
function Layout:widgetIsClicked(id)
    return false
end
function Layout:widgetIsDragged(id)
    return false, 0.0, 0.0
end

function Layout:add(id, definition, overrides)
    if self.widgets[id] == nil or (self.parent.currentFrame - (self.widgets[id].requestedOn or -9000)) > self.parent.invalidationLifetime then
        print("Adding widget,"..tostring(overrides))
        self.widgets[id] = {
            definition = definition,
            size = {},
            state = {}
        }
    end
    self.widgets[id].requestedOn = self.parent.currentFrame
    self.widgets[id].overrides = overrides

    if definition.getSize == nil then error("Control definitions need a getSize function.") end
    self.widgets[id].size = definition.getSize(self, id, overrides)

    self.widgetOrder[#self.widgetOrder+1] = id
end

function Layout:drawStandardBit(bit, bitData, color)
    ---@type Interface.Layout.DrawCommand
    local draw = DrawCommand(bit, bitData, color)
    draw.position[1] = self.splat[1]
    draw.position[2] = self.splat[2]
    draw.size[1] = self.splat[3]
    draw.size[2] = self.splat[4]
    self.draws[#self.draws+1] = draw
end

function Layout:flushDraw()
    for i=1,#self.draws do
        print("?????")
        self.draws[i]:draw(self.parent)
    end
end

function Layout:finalize()
    self.draws = {}
    self.splat = {self.position[1], self.position[2], 0, 0}
    for i=1,#self.widgetOrder do
        local state = self.widgets[self.widgetOrder[i]]
        self.splat[3] = state.size.size[1]
        self.splat[4] = state.size.size[2]
        state.definition.update(self, self.widgetOrder[i], state.overrides)
    end
    self.widgetOrder = {}
end

---@class Interface : Object
---@field resourceInstance Resource|nil
---@field jizzInstance Jizz|nil
---@field jizzProfile Jizz.PhysicsProfile|nil
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
local Interface = Object:extend()

Interface.Layout = Layout

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

    self.renderHandler["Font"] = function(fnt, msg, x, y, w, h)
        love.graphics.setFont(fnt)
        love.graphics.print(msg, x, y)
    end
    self.renderHandler[true] = function(val, data, x, y, w, h)
        love.graphics.rectangle("fill", x, y, w, h)
    end
    self.renderHandler[false] = function(val, data, x, y, w, h)
        love.graphics.rectangle("line", x, y, w, h)
    end
end


function Interface:createContext()
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

    -- I guess its a literal then?
    return self.renderHandler[obj]
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
---@param xO number origin, normalized. 0.5 = middle, 0.0 = left, 1.0 = right
---@param yO number origin, normalized. 0.5 = middle, 0.0 = up, 1.0 = down
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
        newLayout.position = {x,y}
        newLayout.origin = {xO, yO}
        newLayout.requestedOn = self.currentFrame
        if w ~= nil and h ~= nil then
            newLayout.size = {w,h}
        end
        self.layoutStack[id] = newLayout
        return self.layoutStack[id]
    end

    self.layoutStack[id].requestedOn = self.currentFrame
    return self.layoutStack[id]
end


---Places a new element into the layout, 
---@param layout Interface.Layout the control's state identifier. This should be unique.
---@param control table The control definition, eg `Interface.Button`
---@param overrides any|nil Overrides for the control's table
function Interface:element(layout, controlID, control, overrides)
    layout:add(controlID, control, overrides)
end

--- Called at the end of your update.
function Interface:update()
    for k,v in pairs(self.layoutStack) do
        v:finalize()
    end
    self.currentFrame = self.currentFrame + 1
end

---@class Interface.Button
---@field text string
---@field background any The default background for the button, can be any renderable resource or nil.
---@field grow number|nil Will fill width if possible. If supplied, supply as weight.
---@field minimumWidth number The smallest it can get.
---@field minimumHeight number The smallest it can get.
---@field pressed function What happens when pressed.
---@field getSize function returns table like {size={0,0}, flex={-1,-1}}
---@field update function Controls moving the playhead to the next 
Interface.Button = {}

Interface.Button.text = "Button"
Interface.Button.background = nil
---@type love.Font|nil
Interface.Button.font = nil
Interface.Button.minimumWidth = 16.0
Interface.Button.minimumHeight = 16.0
Interface.Button.makeContext=function(ctx)
end
Interface.Button.pressed=function()
end
---@param face Interface.Layout
---@param id string
---@param ovr table
Interface.Button.getSize=function(face, id, ovr)
    local mw = ovr.minimumWidth or Interface.Button.minimumWidth
    local mh = ovr.minimumHeight or Interface.Button.minimumHeight

    ---@type love.Font
    local font = ovr.font or Interface.Button.font

    local fw = font:getWidth(ovr.text or Interface.Button.text)
    return {
        size = {math.max(mw, fw), math.max(font:getHeight(), mh)},
        flex = {
            ovr.grow or Interface.Button.grow or -1.0,
            -1.0
        },
    }
end
---@param face Interface.Layout
---@param id string
---@param ovr table
Interface.Button.update=function(face, id, ovr)
    local color = {0.7, 0.7, 0.7, 1.0}
    if face:widgetIsHovered(id) then
        color = {1.0, 1.0, 1.0, 1.0}
    end

    if face:widgetIsClicked(id) then
        local fn = ovr.pressed or Interface.Button.pressed
        fn()
    end
    face:drawStandardBit(true, color)
    face:drawStandardBit(ovr.font or Interface.Button.font, ovr.text or Interface.Button.text, {1.0, 1.0, 1.0, 1.0})
end


function Interface:draw()
    for k,v in pairs(self.layoutStack) do
        ---@type Interface.Layout
        local l = self.layoutStack[k]
        if l.requestedOn == self.currentFrame then
            love.graphics.setColor(1.0, 1.0, 1.0, 0.1)
            love.graphics.rectangle("fill", l.position[1], l.position[2], l.size[1], l.size[2])
            l:flushDraw()
        end
    end
    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
end

return Interface