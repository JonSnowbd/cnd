local obj = require "cnd.obj"
local mth = require "cnd.mth"

---@class cnd.ui.layout
---@field background any[] table array of either just the [bg], or [bg,data]
---@field padding number
---@field spacing number
---@field id string
---@field parent cnd.ui
---@field position cnd.mth.v2
---@field size cnd.mth.v2
---@field draws cnd.ui.layout.cmd[]
---@field remainingSpace cnd.mth.v2
---@field requestedOn integer
---@field widgets table<string,table>
---@field commands table[]
---@field windowWidthBasis number
---@field currentWidget string|nil
---@field layingOut boolean
---@field stuckWidget string|nil
---@field debug boolean
---@field age integer how many frames old this action is.
local layout = obj:extend()

layout.cmd = require "cnd.ui.drawcommand"

---@param id string
---@param parent cnd.ui
function layout:new(id, parent)
    self.debug = false
    self.padding = parent.defaultPadding or 2.0
    self.spacing = parent.defaultSpacing or 2.0
    self.id = id
    self.parent = parent
    self.position = mth.v2(0,0)
    self.size = mth.v2(0,0)
    self.origin = mth.v2(0,0)
    self.draws = {}
    self.splat = mth.rec(0,0,0,0)
    self.remainingSpace = mth.v2(0,0)
    self.requestedOn = parent.currentFrame
    self.widgets = {}
    self.commands = {}
    self.windowWidthBasis = 0.0
    self.layingOut = false
    self.age = 0
end

--- Every widget has a state persisted for its duration. Wiped when idle for long enough.
---@param key string
---@param defaultValue any If the key is not found, this is inserted and then returned.
---@return any|nil
function layout:widgetGetState(key, defaultValue)
    if self.widgets[self.currentWidget] ~= nil then
        if self.widgets[self.currentWidget].state[key] ~= nil then
            self.widgets[self.currentWidget].state[key] = defaultValue
        end
        return self.widgets[self.currentWidget].state[key]
    end
end

--- Every widget has a state persisted for its duration. Wiped when idle for long enough.
---@param key string
---@param value any
function layout:widgetSetState(key, value)
    if self.widgets[self.currentWidget] ~= nil then
        self.widgets[self.currentWidget].state[key] = value
    end
end
--- Returns the current id. Useful for manually accessing cnd.ui state.
---@return string|nil
function layout:widgetID()
    return self.currentWidget
end
function layout:widgetCursorLocation()
    if self.layingOut or self.widgets[self.currentWidget].state.relativeCursor == nil then
        return -1.0, -1.0
    end
    return self.widgets[self.currentWidget].state.relativeCursor[1], self.widgets[self.currentWidget].state.relativeCursor[2]
end
--- Returns true if the widget is visible, and the cursor is inside
--- the given rect.
---@param rec cnd.mth.rec
---@return boolean
function layout:widgetHovered(rec)
    if self.layingOut then return false end
    local rc = self.widgets[self.currentWidget].state.relativeCursor
    return rec:containsPoint(rc)
end
--- Returns true if the widget is visible and the cursor is inside the rect, 
--- and confirm is pressed.
---@param rec cnd.mth.rec
---@return boolean
function layout:widgetClicked(rec)
    if self.layingOut then return false end
    return self:widgetHovered(rec) and self.parent.confirmState.pressed
end
--- Returns true if the widget is currently the ui focus.
---@return boolean
function layout:widgetFocused()
    if self.layingOut then return false end
    return false
end

function layout:widgetStick()
    self.stuckWidget = self.currentWidget
end
function layout:widgetStuck()
    if self.layingOut then return false end
    return self.stuckWidget == self.currentWidget
end
function layout:widgetUnstick()
    self.stuckWidget = nil
end

function layout:widgetConfirmPressed()
end
function layout:widgetConfirmDown()
    if self.layingOut then return false end
    return self.parent.confirmState.held
end
function layout:widgetCanSideEffect()
    return self.layingOut == false
end

--- Manually mark a bit of the current widget as reserved.
---@param splat cnd.mth.rec
function layout:widgetAddBoundary(splat)
    if self.layingOut then
        if splat.x+splat.w > self.widgets[self.currentWidget].size.x then
            self.widgets[self.currentWidget].size.x = splat.x+splat.w
        end
        if splat.y+splat.h > self.widgets[self.currentWidget].size.y then
            self.widgets[self.currentWidget].size.y = splat.y+splat.h
        end
    end
end
---Pushes a render to the queue, asset can be any love type such as
--- font, texture(and quad in the data parameter), or a Resource such as
--- ImageSheet(and its {x,y} index) or NineSlice. You can use a custom type here
--- too if you gave it a `type()` function and set its draw fn in the UI render handler table.
---@param splat cnd.mth.rec
---@param asset any
---@param data any|nil
---@param color cnd.mth.v2|nil
function layout:widgetDraw(splat, asset, data, color)
    if self.layingOut then
        self:widgetAddBoundary(splat)
        return
    end
    ---@type cnd.ui.layout.cmd
    local draw = layout.cmd(asset, data, color or {1.0, 1.0, 1.0, 1.0})
    local widget = self.widgets[self.currentWidget]
    draw.position = mth.v2(widget.position.x + splat.x,widget.position.y + splat.y)
    draw.size = mth.v2(splat.w,splat.h)
    draw.debug = self.debug
    self.draws[#self.draws+1] = draw
end
--- Like widgetDraw but will not push widget boundaries. Fast. If you know your widget is grid based
--- Prefer to AddBoundary its entirety and then silent draw the individual pieces
---@param splat cnd.mth.rec
---@param asset any
---@param data any|nil
---@param color cnd.mth.v2|nil
function layout:widgetSilentDraw(splat, asset, data, color)
    if self.layingOut then return end
    ---@type cnd.ui.layout.cmd
    local draw = layout.cmd(asset, data, color or {1.0, 1.0, 1.0, 1.0})
    local widget = self.widgets[self.currentWidget]
    draw.position = mth.v2(widget.position.x + splat.x, widget.position.y + splat.y)
    draw.size = mth.v2(splat.w,splat.h)
    draw.debug = self.debug
    self.draws[#self.draws+1] = draw
end

---comment
---@generic SRC
---@generic T : `SRC`
---@param id string the unique identity for this widget
---@param definition SRC
---@param overrides T
function layout:push(id, definition, overrides)
    if self.widgets[id] == nil or (self.parent.currentFrame - (self.widgets[id].requestedOn or -9000)) > self.parent.invalidationLifetime then
        self.widgets[id] = {
            definition = definition,
            state = {},
        }
    end
    self.widgets[id].position = mth.v2(0,0)
    self.widgets[id].size = mth.v2(0,0)
    self.widgets[id].requestedOn = self.parent.currentFrame
    self.widgets[id].overrides = overrides

    self.commands[#self.commands+1] = {
        type = "widget",
        id = id,
    }
end
---comment
---@param basis number 0.5 = smaller items are centered, 0.0 = top, 1.0 = bottom
function layout:pushRow(basis)
    self.commands[#self.commands+1] = {
        type = "row",
        size = mth.v2(0,0),
        position = mth.v2(0,0),
        basis = basis,
        windowBasis = self.windowWidthBasis
    }
end
---@param basis number 0.5 = smaller items are centered, 0.0 = left, 1.0 = right
function layout:pushColumn(basis)
    self.commands[#self.commands+1] = {
        type = "column",
        size = mth.v2(0,0),
        position = mth.v2(0,0),
        basis = basis,
        windowBasis = self.windowWidthBasis
    }
end
function layout:pushBackground(asset, data)
    self.background = {asset, data}
end
---when a row or column is narrower than the window, the 
--- container will be centered based on this. 0.0 = leftmoster, 0.5 = center, 1.0 = rightmost
---@param widthBasis number
function layout:pushWindowBasis(widthBasis)
    self.windowWidthBasis = widthBasis
end
function layout:flushDraw()
    for i=1,#self.draws do
        self.draws[i]:draw(self.parent)
    end
end

---comment
---@param layoutPhase boolean
function layout:finalize(layoutPhase)
    self.layingOut = layoutPhase
    if layoutPhase == false then
        self.draws = {}
    end

    
    local currentContainer = nil
    if layoutPhase then
        local window = mth.rec(self.position.x,self.position.y,0.0,0.0)
        local currentContainerProg = 0.0
        local containerStamp = 0.0
        containerStamp = self.padding
        for i=1,#self.commands do
            local cmd = self.commands[i]
            if cmd.type == "row" or cmd.type == "column" then
                currentContainer = cmd
                currentContainerProg = 0.0
                cmd.position.x = self.padding
                cmd.position.y = containerStamp
                cmd.size.x = 0.0
                cmd.size.y = 0.0
                -- Tally up its children
                for j=i+1,#self.commands do
                    local next = self.commands[j]
                    if next.type == "row" or next.type == "column" then
                        i = j
                        break
                    end
                    if currentContainer == nil then error("Missed a container.") end
                    self.currentWidget = next.id
                    local widget = self.widgets[next.id]
                    if widget.definition == nil or widget.definition.layout == nil then
                        error("Widget definition for "..next.id.." either doesnt exist, or needs a layout(ui, ovr) function.")
                    end
                    widget.definition.layout(self, widget.overrides)

                    if currentContainer.type == "row" then
                        currentContainer.size.x = currentContainer.size.x + widget.size.x + self.spacing
                        if widget.size.y > currentContainer.size.y then
                            currentContainer.size.y = widget.size.y
                        end
                        widget.position.x = currentContainerProg
                        widget.position.y = 0.0
                        currentContainerProg = currentContainerProg + widget.size.x + self.spacing
                    else
                        if widget.size.x > currentContainer.size.x then
                            currentContainer.size.x = widget.size.x
                        end
                        currentContainer.size.y = currentContainer.size.y + widget.size.y + self.spacing
                        widget.position.y = currentContainerProg
                        widget.position.x = 0.0
                        currentContainerProg = currentContainerProg + widget.size.y + self.spacing
                    end
                end
                if cmd.type == "row" then
                    cmd.size.x = cmd.size.x - self.spacing
                else
                    cmd.size.y = cmd.size.y - self.spacing
                end
                containerStamp = containerStamp + cmd.size.y + self.spacing
                if cmd.size.x > window.w then
                    window.w = cmd.size.x
                end
                window.h = window.h + cmd.size.y + self.spacing
            end
        end
        window.h = window.h - self.spacing
        self.size.x = math.max(self.size.x, window.w + (self.padding*2.0))
        self.size.y = math.max(self.size.y, window.h + (self.padding*2.0))
        self.position.x = window.x - (self.size.x * self.origin.x)
        self.position.y = window.y - (self.size.y * self.origin.y)
    else
        if self.background == nil and self.parent.defaultBackground ~= nil then
            self.background = {self.parent.defaultBackground, self.parent.defaultBackgroundData}
        end
        if self.background then
            local draw = layout.cmd(self.background[1], self.background[2], {1.0, 1.0, 1.0, 1.0})
            draw.position = mth.v2(self.position.x, self.position.y)
            draw.size = mth.v2(self.size.x, self.size.y)
            draw.debug = self.debug
            self.draws[#self.draws+1] = draw
        end
        for i=1,#self.commands do
            local cmd = self.commands[i]
            if cmd.type == "row" or cmd.type == "column" then
                -- Center out relative to the window basis.

                local realWidth = self.size.x - (self.padding*2)
                cmd.position.x = cmd.position.x + ((realWidth-cmd.size.x) * cmd.windowBasis)

                currentContainer = cmd
                -- Tally up its children
                for j=i+1,#self.commands do
                    local next = self.commands[j]
                    if next.type == "row" or next.type == "column" then
                        i = j
                        break
                    end
                    if currentContainer == nil then error("Missed a container.") end
                    self.currentWidget = next.id
                    local widget = self.widgets[next.id]
                    widget.position.x = self.position.x + currentContainer.position.x + widget.position.x
                    widget.position.y = self.position.y + currentContainer.position.y + widget.position.y
                    if currentContainer.type == "row" then
                        widget.position.y = widget.position.y + ((currentContainer.size.y-widget.size.y) * currentContainer.basis)
                    else
                        widget.position.x = widget.position.x + ((currentContainer.size.x-widget.size.x) * currentContainer.basis)
                    end
                    widget.state.relativeCursor = self.parent.cursor - widget.position
                    widget.definition.layout(self, widget.overrides)
                end
            end
        end
        self.commands = {}
    end
end

return layout