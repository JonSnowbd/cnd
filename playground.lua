local Object = require "dep.classic"
local interp = require "dep.interp"

---@class Playground.Shader : Object
---@field needsTime boolean
---@field needsTransitionProgress boolean
---@field needsWindowSize boolean
---@field needsCanvasSize boolean
---@field raw love.Shader
local Shader = Object:extend()

function Shader:new(psFileData,vsFileData)
    if vsFileData ~= nil then
        self.raw = love.graphics.newShader(psFileData, vsFileData)
    else
        self.raw = love.graphics.newShader(psFileData)
    end

    self.needsTime = self.raw:hasUniform("time")
    self.needsTransitionProgress = self.raw:hasUniform("transitionProgress")
    self.needsWindowSize = self.raw:hasUniform("windowSize")
    self.needsCanvasSize = self.raw:hasUniform("canvasSize")
end

---@class Playground : Object
---@field size integer[] in pixels the size of the rendertarget
---@field gameCanvas love.Canvas
---@field flopCanvas love.Canvas
---@field snapshotCanvas love.Canvas
---@field previousCanvas love.Canvas? 
---@field shaders table<string,Playground.Shader>
---@field previousShader love.Shader
---@field transitionTimes number[] 2d vector, [1] is the current time, [2] is the duration.
---@field transitionShader string
---@field transitionEase function?
---@field finalOutputTransform love.Transform the transform used to draw the game canvas to the screen.
---@field debugFont love.Font
---@field barColor number[] When the window is sized incorrectly, this is the color of the blackbars
---@field camera Playground.Camera
local Playground = Object:extend()

Playground.Shader = Shader

---@class Playground.Camera : Object
---@field screenSize number[]
---@field dirty boolean
---@field rotation number
---@field zoom number[]
---@field position number[]
---@field snapped boolean
---@field normalizedOffset number[] 0.0, 0.0 = top left camera. 0.5, 0.5 = middle camera
---@field transform love.Transform the transform of the camera, updated in playground:update()
local Camera = Object:extend()

function Camera:new(screenWidth, screenHeight)
    self.dirty = true
    self.rotation = 0.0
    self.zoom = {1.0, 1.0}
    self.position = {0.0, 0.0}
    self.snapped = true
    self.normalizedOffset = {0.5, 0.5}
    self.transform = love.math.newTransform()
    self.screenSize = {screenWidth, screenHeight}
end
function Camera:move(x, y)
    self.dirty = true
    self.position[1] = self.position[1] + x
    self.position[2] = self.position[2] + y
end
function Camera:setPosition(x, y)
    self.dirty = true
    self.position[1] = x
    self.position[2] = y
end
---@param r number in radians
function Camera:rotate(r)
    self.dirty = true
    self.rotation = self.rotation + r
end
---@param r number in radians
function Camera:setRotation(r)
    self.dirty = true
    self.rotation = r
end

function Camera:setZoom(x, y)
    self.dirty = true
    self.zoom[1] = x
    self.zoom[2] = y
end

---@return love.Transform
function Camera:getTransform()
    if self.dirty then
        local xOffset = self.screenSize[1] * self.normalizedOffset[1]
        local yOffset = self.screenSize[2] * self.normalizedOffset[2]

        if self.snapped then
            local xSnap = 1.0/self.zoom[1]
            local ySnap = 1.0/self.zoom[2]
            self.transform
            :reset()
            :scale(self.zoom[1], self.zoom[2])
            :translate(interp.snap(xOffset,xSnap)/self.zoom[1], interp.snap(yOffset, ySnap)/self.zoom[2])
            :rotate(self.rotation)
            :translate(-interp.snap(self.position[1], xSnap), -interp.snap(self.position[2], ySnap))
        else
            self.transform
            :reset()
            :scale(self.zoom[1], self.zoom[2])
            :translate(xOffset/self.zoom[1], yOffset/self.zoom[2])
            :rotate(self.rotation)
            :translate(-self.position[1], -self.position[2])
        end
        self.dirty = false
    end
    return self.transform
end
--- Takes a screenshot of the current state of the game rt. The picture will be stored
--- in `Playground.snapshotCanvas`
function Playground:snapshot()
    local previous = love.graphics.getCanvas()
    love.graphics.push()
    love.graphics.replaceTransform(love.math.newTransform())
    love.graphics.setCanvas(self.snapshotCanvas)
    love.graphics.clear(0.0, 0.0, 0.0, 0.0)
    love.graphics.draw(self.gameCanvas)
    love.graphics.pop()

    love.graphics.setCanvas(previous)
end
--- Creates and stores a shader under a name. The table provided via defaults
--- will upload data to uniforms as defaults. 
--- To autofeed, simply add the any of the following exports:
--- - `uniform sampler2D snapshotCanvas` don't request this for transitions, but if you want to peek at the snapshot for an effect, this is it.
--- - `uniform float transitionProgress` is a float between 0.0 and 1.0 inclusive. 0.0 is completely untransitioned, and 1.0 is complete.
--- - `uniform float aspectRatio` the aspect ratio of the current playground config
--- - `uniform float time` this is the time the game has been open
--- - `uniform vec2 canvasSize` this is the size of the canvas
--- - `uniform vec2 windowSize` this is the size of the window
---@param name string the name of the shader internally.
---@param pixelShaderPath string a path to the pixel shader
---@param vertexShaderPath? string optional, you can make a custom vertex shader
---@param defaults? table a table of uniforms to upload after being made. for example `{seed=30.0, smoothness=0.005}`
function Playground:makeShader(name, pixelShaderPath, vertexShaderPath, defaults)
    local px = love.filesystem.read(pixelShaderPath)
    local vx = nil
    if vertexShaderPath ~= nil then
        vx = love.filesystem.read(vertexShaderPath)
    end
    self.shaders[name] = Playground.Shader(px, vx)
end


---@param name string shader name
---@param data table the data to send. for example {seed=30.0, smoothness=3.0, direction={1.0, 0.0}}
function Playground:updateShader(name, data)
    for k, v in pairs(data) do
        self.shaders[name].raw:send(k, v)
    end
end

---@param name string
---@param data? table optional data to send to the shader that gets bound
function Playground:bindShader(name, data)
    local shader = self.shaders[name]
    if data ~= nil then
        self:updateShader(name, data)
    end
    if shader == nil then
        error("Failed to get shader "..name.." try loading it first.")
        return
    end
    self.previousShader = love.graphics.getShader()

    if shader.needsTime then
        shader.raw:send("time", love.timer.getTime())
    end
    if shader.needsTransitionProgress then
        local progress = interp.clamp(1.0-(self.transitionTimes[1]/self.transitionTimes[2]), 0.0, 1.0)
        if self.transitionEase ~= nil then
            progress = interp.lerp(0.0, 1.0, progress, self.transitionEase)
        end
        shader.raw:send("transitionProgress", progress)
    end
    if shader.needsCanvasSize then
        shader.raw:send("canvasSize", self.size)
    end
    if shader.needsWindowSize then
        local wx, wy = love.graphics.getWidth(), love.graphics.getHeight()
        shader.raw:send("windowSize", {wx, wy})
    end
    love.graphics.setShader(shader.raw)
end
function Playground:unbindShader()
    love.graphics.setShader(self.previousShader)
    self.previousShader = nil
end

--- Binds the source, and draws it to the cleared target.
--- This is used for multiple shader runs, for example if you have
--- a directional blur that will be repeated you can do:
--- - `pg:flop(source, nil, "blur", {direction={1, 0}})`
--- - `pg:flop(pg.flopCanvas, source, "blur", {direction={0, 1}})`
--- Getting its name flop, as you flip flop between canvases compounding the effect.
---@param source love.Canvas the flop happens FROM this canvas
---@param target? love.Canvas the flop happens TO this canvas
---@param shaderName string the shader to flop with
---@param data? table optional shader data passed before running
function Playground:flop(source, target, shaderName, data)
    local previousCanvas = love.graphics.getCanvas()
    local r,g,b,a = love.graphics.getColor()
    if target == nil then
        target = self.flopCanvas
    end
    love.graphics.push()
    love.graphics.replaceTransform(love.math.newTransform())

    love.graphics.setCanvas(target)
    love.graphics.clear(0.0, 0.0, 0.0, 0.0)
    self:bindShader(shaderName, data)
    love.graphics.draw(source)
    self:unbindShader()

    love.graphics.pop()
    love.graphics.setCanvas(previousCanvas)
    love.graphics.setColor(r,g,b,a)
end

--- Enables drawing to the internal game frame
function Playground:bind()
    self.previousCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(self.gameCanvas)
end
--- Disables drawing to the internal game frame, and restores
--- the previous canvas.
function Playground:unbind()
    love.graphics.setCanvas(self.previousCanvas)
    self.previousCanvas = nil
end

--- Overrides the current transform(with a push, so dont forget to disable after to preserve your previous settings)
function Playground:enableCamera()
    love.graphics.push()
    love.graphics.replaceTransform(self.camera:getTransform())
end
--- Pops the transform.
function Playground:disableCamera()
    love.graphics.pop()
end

--- Great for drawing complex objects, lets you treat everything
--- as if it was in 'local' space. 
---@param x? number
---@param y? number
---@param r? number
---@param sx? number
---@param sy? number
---@param ox? number
---@param oy? number
function Playground:pushTransform(x,y,r,sx,sy,ox,oy)
    love.graphics.push()
    love.graphics.scale(sx or 1.0, sy or 1.0)
    love.graphics.rotate(r or 0.0)
    love.graphics.translate((ox or 0.0)*-1.0, (oy or 0.0)*-1.0)
    love.graphics.translate(x or 0.0, y or 0.0)
end
function Playground:popTransform()
    love.graphics.pop()
end

--- Takes a screenshot, and then fades from that screenshot to whatever is currently running.
--- You don't need to organize anything, just `x:triggerTransition(1.0)` and then swap scene in update.
---@param duration number
---@param shaderName? string the name of the shader you want to use. if none is provided, fade transition will be used.
---@param shaderParams? table parameters to update once on transition begin. for example `{seed = 30.0}`
function Playground:triggerTransition(duration, shaderName, shaderParams)
    self:snapshot()
    if shaderName == nil then shaderName = 'fadeTransition' end
    self.transitionShader = shaderName
    if shaderParams ~= nil then
        for k, v in pairs(shaderParams) do
            if self.shaders[shaderName].raw:hasUniform(k) then
                self.shaders[shaderName].raw:send(k, v)
            end
        end
    end
    self.transitionTimes = {duration, duration}
end
--- To be called at AFTER your logic in update loop
function Playground:update()
    local dt = love.timer.getDelta()
    if self.transitionTimes[1] >= 0.0 then
        self.transitionTimes[1] = self.transitionTimes[1] - dt
    end
end
--- To be called AFTER your draw calls in the draw loop
---@param finalShader? string
---@param finalShaderData? table
function Playground:draw(finalShader, finalShaderData)
    love.graphics.setCanvas()
    love.graphics.clear(self.barColor[1],self.barColor[2], self.barColor[3], self.barColor[4])
    local xs = love.graphics.getWidth() / self.gameCanvas:getWidth()
    local ys = love.graphics.getHeight() / self.gameCanvas:getHeight()
    local s = math.min(xs, ys)

    -- local xo = (love.graphics.getWidth() - (self.gameCanvas:getWidth()*s)) * 0.5
    -- local yo = (love.graphics.getHeight() - (self.gameCanvas:getHeight()*s)) *0.5
    local xo = (love.graphics.getWidth() - (self.gameCanvas:getWidth()*s)) * 0.5
    local yo = (love.graphics.getHeight() - (self.gameCanvas:getHeight()*s)) *0.5
    self.finalOutputTransform:reset():translate(xo, yo):scale(s, s)

    if finalShader ~= nil then
        self:bindShader(finalShader, finalShaderData)
    end
    love.graphics.draw(self.gameCanvas, self.finalOutputTransform)
    if finalShader ~= nil then
        self:unbindShader()
    end

    if self.transitionTimes[1] >= 0.0 then
        self:bindShader(self.transitionShader)
        love.graphics.draw(self.snapshotCanvas, self.finalOutputTransform)
        self:unbindShader()
    end
end

--- Simple qol method to make a canvas that fits the playground
---@return love.Canvas
function Playground:makeLayer()
    return love.graphics.newCanvas(self.size[1], self.size[2])
end


--- Gets the mouse position in relation to where the final output will be, taking
--- into account RT size, window size, and black bars.
---@return number mX
---@return number mY
function Playground:getMouse()
    local mx, my = love.mouse.getPosition()
    mx, my = self.finalOutputTransform:inverseTransformPoint(mx, my)
    return mx, my
end
--- Gets the mouse position in relation to where the final output will be, taking
--- into account RT size, window size, and black bars, and camera transform.
---@return number mX
---@return number mY
function Playground:getWorldMouse()
    local mx, my = love.mouse.getPosition()
    mx, my = self.finalOutputTransform:inverseTransformPoint(mx, my)
    mx, my = self.camera:getTransform():inverseTransformPoint(mx, my)
    return mx, my
end

function Playground:new(width, height)
    self.size = {width, height}
    self.gameCanvas = love.graphics.newCanvas(width, height)
    self.flopCanvas = love.graphics.newCanvas(width, height)
    self.snapshotCanvas = love.graphics.newCanvas(width, height)
    self.transitionEase = interp.quad.out
    self.shaders = {}
    self.previousShader = nil
    self.previousCanvas = nil
    self.transitionTimes = {-1,1}
    self.debugFont = love.graphics.newFont("dep/font/pixel.fnt")
    self:makeShader("perlinTransition", "dep/shader/perlin_transition.ps.glsl")
    self:makeShader("fadeTransition", "dep/shader/fade_transition.ps.glsl")
    self:makeShader("pixelPlus", "dep/shader/pixel_plus.ps.glsl")
    self.transitionShader = "fadeTransition"
    self.finalOutputTransform = love.math.newTransform()
    self.barColor = {0.0, 0.0, 0.0, 1.0}
    self.camera = Camera(width, height)
end

return Playground