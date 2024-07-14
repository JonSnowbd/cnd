local mth = require "cnd.mth"
---@class cnd.ui.slider
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

--- If true the value changed callback will be called the entire
--- duration of the slide interaction.
Slider.constantCallback = false

Slider.width = 50.0
Slider.height = 6.0
Slider.value = 0.5
Slider.valueChanged=function(v) end

---@param ui cnd.ui.layout
---@param ovr table
Slider.layout = function(ui, ovr)
    local w = ovr.width or Slider.width
    local h = ovr.height or Slider.height
    local bgCol = ovr.backgroundColor or Slider.backgroundColor
    local col = ovr.color or Slider.color
    local splat = mth.rec(0,0,w,h)
    if ui:widgetHovered(splat) then
        col = ovr.colorHover or Slider.colorHover
        if ui:widgetConfirmDown() and ui.age >= 2 then
            col = ovr.colorActive or Slider.colorActive
            ui:widgetStick()
        end
    end

    if ui:widgetStuck() then
        local constant = ovr.constantCallback or Slider.constantCallback
        col = ovr.colorActive or Slider.colorActive
        local cursor = ui:widgetCursorLocation()
        local v = mth.clamp(cursor.x/w, 0.0, 1.0)
        local fn = ovr.valueChanged or Slider.valueChanged
        if constant then
            fn(v)
        end
        if ui:widgetConfirmDown() == false then
            if not constant then
                fn(v)
            end
            ui:widgetUnstick()
        end
    end

    ui:widgetDraw(splat, (ovr.background or Slider.background), (ovr.backgroundData or Slider.backgroundData), bgCol)
    splat.w = splat.w * (ovr.value or Slider.value)
    ui:widgetDraw(splat, (ovr.foreground or Slider.foreground), (ovr.foregroundData or Slider.foregroundData), col)
end

return Slider