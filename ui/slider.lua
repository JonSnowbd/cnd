local vec = require "dep.vec"
local interp = require "dep.interp"
---@class Interface.Slider
local Slider = {}


Slider.background = true
Slider.backgroundData = nil
Slider.backgroundColor = {1.0, 1.0, 1.0, 1.0}
Slider.foreground = true
Slider.foregroundData = nil
--- Background color when unhovered
Slider.color = {0.9, 0.6, 0.6, 1.0}
--- Background color when hovered
Slider.colorHover = {1.0, 0.8, 0.8, 1.0}
--- Background color when confirm is down
Slider.colorActive = {1.0, 1.0, 1.0, 1.0}
--- When the slider has marks, this is used to draw it.
---@type any
Slider.mark = true
--- And this will be the mark data passed.
---@type any
Slider.markData = nil
--- 
---@type number[]|nil
Slider.marks = nil
Slider.width = 50.0
Slider.height = 6.0
Slider.value = 0.5
Slider.valueChanged=function(v) end

---comment
---@param ui Interface.Layout
---@param ovr table
Slider.layout = function(ui, ovr)
    local w = ovr.width or Slider.width
    local h = ovr.height or Slider.height
    local bgCol = ovr.backgroundColor or Slider.backgroundColor
    local col = ovr.color or Slider.color
    if ui:widgetHovered(0,0,w,h) then
        col = ovr.colorHover or Slider.colorHover
        if ui:widgetConfirmDown() and ui.age >= 2 then
            col = ovr.colorActive or Slider.colorActive
            ui:widgetStick()
        end
    end

    if ui:widgetStuck() then
        col = ovr.colorActive or Slider.colorActive
        local x, _ = ui:widgetCursorLocation()
        local v = interp.clamp(x/w, 0.0, 1.0)
        local fn = ovr.valueChanged or Slider.valueChanged
        fn(v)
        if ui:widgetConfirmDown() == false then
            ui:widgetUnstick()
        end
    end

    ui:widgetDraw(0,0,w,h, (ovr.background or Slider.background), (ovr.backgroundData or Slider.backgroundData), bgCol)
    ui:widgetDraw(0,0,w*(ovr.value or Slider.value),h, (ovr.foreground or Slider.foreground), (ovr.foregroundData or Slider.foregroundData), col)
end

return Slider