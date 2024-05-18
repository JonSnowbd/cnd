local Object = require "dep.classic"
local vec    = require "dep.vec"

---@class Interface.Layout
---@field padding number
---@field spacing number
---@field id string
---@field parent Interface
---@field position number[]
---@field size number[]
---@field draws Interface.Layout.DrawCommand[]
---@field remainingSpace number[]
---@field requestedOn integer
---@field widgets table<string,table>
---@field commands table[]
---@field windowWidthBasis number
---@field currentWidget string|nil
---@field layingOut boolean
---@field stuckWidget string|nil
---@field debug boolean
local Layout = Object:extend()

Layout.DrawCommand = require "dep.ui.drawcommand"

function Layout:new(id, parent)
    self.debug = false
    self.padding = 2
    self.spacing = 1
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
    self.commands = {}
    self.windowWidthBasis = 0.0
    self.layingOut = false
end

--- Every widget has a state persisted for its duration. Wiped when idle for long enough.
---@param key string
---@param defaultValue any If the key is not found, this is inserted and then returned.
---@return any|nil
function Layout:widgetGetState(key, defaultValue)
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
function Layout:widgetSetState(key, value)
    if self.widgets[self.currentWidget] ~= nil then
        self.widgets[self.currentWidget].state[key] = value
    end
end
--- Returns the current id. Useful for manually accessing interface state.
---@return string|nil
function Layout:widgetID()
    return self.currentWidget
end
function Layout:widgetCursorLocation()
    if self.layingOut or self.widgets[self.currentWidget].state.relativeCursor == nil then
        return -1.0, -1.0
    end
    return self.widgets[self.currentWidget].state.relativeCursor[1], self.widgets[self.currentWidget].state.relativeCursor[2]
end
--- Returns true if the widget is visible, and the cursor is inside
--- the given rect.
---@param x number
---@param y number
---@param w number
---@param h number
---@return boolean
function Layout:widgetHovered(x, y, w, h)
    if self.layingOut then return false end
    local rc = self.widgets[self.currentWidget].state.relativeCursor
    return vec.isInRect(rc[1], rc[2], x, y, w, h)
end
--- Returns true if the widget is visible and the cursor is inside the rect, 
--- and confirm is pressed.
---@param x number
---@param y number
---@param w number
---@param h number
---@return boolean
function Layout:widgetClicked(x, y, w, h)
    if self.layingOut then return false end
    return self:widgetHovered(x,y,w,h) and self.parent.confirmState.pressed
end
--- Returns true if the widget is currently the ui focus.
---@return boolean
function Layout:widgetFocused()
    if self.layingOut then return false end
    return false
end

function Layout:widgetStick()
    self.stuckWidget = self.currentWidget
end
function Layout:widgetStuck()
    if self.layingOut then return false end
    return self.stuckWidget == self.currentWidget
end
function Layout:widgetUnstick()
    self.stuckWidget = nil
end

function Layout:widgetConfirmPressed()
end
function Layout:widgetConfirmDown()
    if self.layingOut then return false end
    return self.parent.confirmState.held
end
function Layout:widgetCanSideEffect()
    return self.layingOut == false
end

--- Manually mark a bit of the current widget as reserved.
---@param x number
---@param y number
---@param w number
---@param h number
function Layout:widgetAddBoundary(x, y, w, h)
    if self.layingOut then
        if x+w > self.widgets[self.currentWidget].size[1] then
            self.widgets[self.currentWidget].size[1] = x+w
        end
        if y+h > self.widgets[self.currentWidget].size[2] then
            self.widgets[self.currentWidget].size[2] = y+h
        end
    end
end
---Pushes a render to the queue, asset can be any love type such as
--- font, texture(and quad in the data parameter), or a Resource such as
--- ImageSheet(and its {x,y} index) or NineSlice. You can use a custom type here
--- too if you gave it a `type()` function and set its draw fn in the UI render handler table.
---@param x number
---@param y number
---@param w number
---@param h number
---@param asset any
---@param data any|nil
---@param color number[]|nil
function Layout:widgetDraw(x, y, w, h, asset, data, color)
    if self.layingOut then
        self:widgetAddBoundary(x, y, w, h)
        return
    end
    ---@type Interface.Layout.DrawCommand
    local draw = Layout.DrawCommand(asset, data, color or {1.0, 1.0, 1.0, 1.0})
    local widget = self.widgets[self.currentWidget]
    draw.position[1] = widget.position[1] + x
    draw.position[2] = widget.position[2] + y
    draw.size[1] = w
    draw.size[2] = h
    draw.debug = self.debug
    self.draws[#self.draws+1] = draw
end
--- Like widgetDraw but will not push widget boundaries. Fast. If you know your widget is grid based
--- Prefer to AddBoundary its entirety and then silent draw the individual pieces
---@param x number
---@param y number
---@param w number
---@param h number
---@param asset any
---@param data any|nil
---@param color number[]|nil
function Layout:widgetSilentDraw(x, y, w, h, asset, data, color)
    if self.layingOut then return end
    ---@type Interface.Layout.DrawCommand
    local draw = Layout.DrawCommand(asset, data, color or {1.0, 1.0, 1.0, 1.0})
    local widget = self.widgets[self.currentWidget]
    draw.position[1] = widget.position[1] + x
    draw.position[2] = widget.position[2] + y
    draw.size[1] = w
    draw.size[2] = h
    draw.debug = self.debug
    self.draws[#self.draws+1] = draw
end

---comment
---@generic SRC
---@generic T : `SRC`
---@param id string the unique identity for this widget
---@param definition SRC
---@param overrides T
function Layout:push(id, definition, overrides)
    if self.widgets[id] == nil or (self.parent.currentFrame - (self.widgets[id].requestedOn or -9000)) > self.parent.invalidationLifetime then
        self.widgets[id] = {
            definition = definition,
            state = {},
        }
    end
    self.widgets[id].position = {0,0}
    self.widgets[id].size = {0,0}
    self.widgets[id].requestedOn = self.parent.currentFrame
    self.widgets[id].overrides = overrides

    self.commands[#self.commands+1] = {
        type = "widget",
        id = id,
    }
end
---comment
---@param basis number 0.5 = smaller items are centered, 0.0 = top, 1.0 = bottom
function Layout:pushRow(basis)
    self.commands[#self.commands+1] = {
        type = "row",
        size = {0,0},
        position = {0,0},
        basis = basis,
        windowBasis = self.windowWidthBasis
    }
end
---@param basis number 0.5 = smaller items are centered, 0.0 = left, 1.0 = right
function Layout:pushColumn(basis)
    self.commands[#self.commands+1] = {
        type = "column",
        size = {0,0},
        position = {0,0},
        basis = basis,
        windowBasis = self.windowWidthBasis
    }
end
function Layout:pushBackground(asset, data)
    self.background = {asset, data}
end
---when a row or column is narrower than the window, the 
--- container will be centered based on this. 0.0 = leftmoster, 0.5 = center, 1.0 = rightmost
---@param widthBasis number
function Layout:pushWindowBasis(widthBasis)
    self.windowWidthBasis = widthBasis
end
function Layout:flushDraw()
    for i=1,#self.draws do
        self.draws[i]:draw(self.parent)
    end
end

---comment
---@param layoutPhase boolean
function Layout:finalize(layoutPhase)
    self.layingOut = layoutPhase
    if layoutPhase == false then
        self.draws = {}
    end

    
    local currentContainer = nil
    if layoutPhase then
        local window = {self.position[1],self.position[2],0.0,0.0}
        local currentContainerProg = 0.0
        local containerStamp = 0.0
        containerStamp = self.padding
        for i=1,#self.commands do
            local cmd = self.commands[i]
            if cmd.type == "row" or cmd.type == "column" then
                currentContainer = cmd
                currentContainerProg = 0.0
                cmd.position[1] = self.padding
                cmd.position[2] = containerStamp
                cmd.size[1] = 0.0
                cmd.size[2] = 0.0
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
                        currentContainer.size[1] = currentContainer.size[1] + widget.size[1] + self.spacing
                        if widget.size[2] > currentContainer.size[2] then
                            currentContainer.size[2] = widget.size[2]
                        end
                        widget.position[1] = currentContainerProg
                        widget.position[2] = 0.0
                        currentContainerProg = currentContainerProg + widget.size[1] + self.spacing
                    else
                        if widget.size[1] > currentContainer.size[1] then
                            currentContainer.size[1] = widget.size[1]
                        end
                        currentContainer.size[2] = currentContainer.size[2] + widget.size[2] + self.spacing
                        widget.position[2] = currentContainerProg
                        widget.position[1] = 0.0
                        currentContainerProg = currentContainerProg + widget.size[2] + self.spacing
                    end
                end
                if cmd.type == "row" then
                    cmd.size[1] = cmd.size[1] - self.spacing
                else
                    cmd.size[2] = cmd.size[2] - self.spacing
                end
                containerStamp = containerStamp + cmd.size[2] + self.spacing
                if cmd.size[1] > window[3] then
                    window[3] = cmd.size[1]
                end
                window[4] = window[4] + cmd.size[2] + self.spacing
            end
        end
        window[4] = window[4] - self.spacing
        self.size[1] = math.max(self.size[1], window[3] + (self.padding*2.0))
        self.size[2] = math.max(self.size[2], window[4] + (self.padding*2.0))
        self.position[1] = window[1] - (self.size[1] * self.origin[1])
        self.position[2] = window[2] - (self.size[2] * self.origin[2])
    else
        if self.background then
            local draw = Layout.DrawCommand(self.background[1], self.background[2], {1.0, 1.0, 1.0, 1.0})
            draw.position[1] = self.position[1]
            draw.position[2] = self.position[2]
            draw.size[1] = self.size[1]
            draw.size[2] = self.size[2]
            draw.debug = self.debug
            self.draws[#self.draws+1] = draw
        end
        for i=1,#self.commands do
            local cmd = self.commands[i]
            if cmd.type == "row" or cmd.type == "column" then
                -- Center out relative to the window basis.

                local realWidth = self.size[1] - (self.padding*2)
                cmd.position[1] = cmd.position[1] + ((realWidth-cmd.size[1]) * cmd.windowBasis)

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
                    widget.position[1] = self.position[1] + currentContainer.position[1] + widget.position[1]
                    widget.position[2] = self.position[2] + currentContainer.position[2] + widget.position[2]
                    if currentContainer.type == "row" then
                        widget.position[2] = widget.position[2] + ((currentContainer.size[2]-widget.size[2]) * currentContainer.basis)
                    else
                        widget.position[1] = widget.position[1] + ((currentContainer.size[1]-widget.size[1]) * currentContainer.basis)
                    end

                    local rx, ry = vec.sub(self.parent.cursor[1], self.parent.cursor[2], widget.position[1], widget.position[2])
                    widget.state.relativeCursor = {rx, ry}
                    widget.definition.layout(self, widget.overrides)
                end
            end
        end
        self.commands = {}
    end

    -- -- If its go time, tally the window size
    -- if layoutPhase == false then
    --     local y = 0.0
    --     for i=1,#self.commands do
    --         local cmd = self.commands[i]
    --         if cmd.type == "row" or cmd.type == "column" then
    --             if cmd.size[1] > window[3] then
    --                 window[3] = cmd.size[1]
    --             end
    --             cmd.position[1] = self.padding
    --             cmd.position[2] = y

    --             print("Group#"..i.." at "..cmd.position[1].."x"..cmd.position[2].." and "..cmd.size[1].."x"..cmd.size[2])

    --             y = y + cmd.size[2]
    --             window[4] = window[4] + cmd.size[2]
    --         end
    --     end
    --     -- Apply origin
    --     window[1] = window[1] - (window[3] * self.origin[1])
    --     window[2] = window[2] - (window[4] * self.origin[2])
    -- end

    -- -- STUFF
    -- for i=1,#self.commands do
    --     local cmd = self.commands[i]

    --     -- When a direction changes, go back to the previous container and tally the sizes
    --     if cmd.type == "row" or cmd.type == "column" then
    --         -- If the previous container is valid, update it
    --         if currentContainer ~= nil and currentContainerInd >= 1 and currentContainerInd <= #self.commands then
    --             local pushed = false
    --             for j=currentContainerInd+1,#self.commands do
    --                 if self.commands[j].type == "row" or self.commands[j].type == "column" then break end

    --                 local nextWidget = self.widgets[self.commands[j].id]
    --                 if currentContainer.type == "row" then
    --                     cmd.size[1] = cmd.size[1] + nextWidget.size[1] + self.spacing
    --                     if nextWidget.size[2] > cmd.size[2] then cmd.size[2] = nextWidget.size[2] end
    --                     pushed = true
    --                 else
    --                     if nextWidget.size[1] > cmd.size[1] then cmd.size[1] = nextWidget.size[1] end
    --                     cmd.size[2] = cmd.size[2] + nextWidget.size[2]
    --                     pushed = true
    --                 end
    --             end

    --             if pushed then
    --                 cmd.size[1] = cmd.size[1] - self.spacing
    --                 cmd.size[2] = cmd.size[2] - self.spacing
    --             end
    --         end

    --         -- Then remember where we gotta go next change( or end)
    --         currentContainer = cmd
    --         currentContainerInd = i
    --         containerStamp = 0.0

    --         inRow = currentContainer.type == "row"
    --     end

    --     if cmd.type == "widget" then
    --         self.currentWidget = cmd.id
    --         local widget = self.widgets[self.currentWidget]
    --         local layer = widget.definition.layout
    --         if layer == nil then error("Widget Definitions must contain a layout function") end
    --         if currentContainer == nil then error("Free floating widget outside container. Did you forget to start with a row/column?") end
    --         if layoutPhase == false then
    --             if inRow then
    --                 local offset = (currentContainer.size[2] - widget.size[2]) * currentContainer.basis
    --                 widget.position[1] = window[1]+currentContainer.position[1] + containerStamp
    --                 widget.position[2] = window[2]+currentContainer.position[2] + offset
    --                 containerStamp = containerStamp + widget.size[1] + self.spacing
    --             else
    --                 local offset = (currentContainer.size[1] - widget.size[1]) * currentContainer.basis
    --                 widget.position[1] = window[1]+currentContainer.position[1] + offset
    --                 widget.position[2] = window[2]+currentContainer.position[2] + containerStamp
    --                 containerStamp = containerStamp + widget.size[2] + self.spacing
    --             end
    --         end
    --         layer(self, widget.overrides)
    --     end

    -- end
    -- if layoutPhase == false then
    --     self.commands = {}
    --     local bgDraw = Layout.DrawCommand(true, nil, {1.0, 0.0, 0.0, 0.8})
    --     bgDraw.position[1] = window[1]
    --     bgDraw.position[2] = window[2]
    --     bgDraw.size[1] = window[3]
    --     bgDraw.size[2] = window[4]
    --     self.draws[#self.draws+1] = bgDraw
    -- end
end

return Layout