local mth = require "cnd.mth"
---@diagnostic disable: cast-local-type

---@class cnd.ui.label
---@field color number[] The Label color
---@field colorHover number[]|nil The Label color, if hovered.
---@field colorActive number[]|nil The Label color, if hovered and pressed.
---@field pressed function What happens when pressed.
---@field font love.Font The draw value, supports anything that can be drawn by the ui.
local Label = {}

Label.color = {0.2, 0.2, 0.2, 1.0}
Label.text = "Default Text"
Label.pressed = function() end

---@param face cnd.ui.layout
---@param ovr table
Label.layout = function(face, ovr)
    local fnt = ovr.font or Label.font or face.parent.defaultFont
    local txt = ovr.text or Label.text
    local splat = mth.rec(0, 0, fnt:getWidth(txt), fnt:getHeight())
    local color = ovr.color or Label.color
    if face:widgetClicked(splat) then
        local fn = ovr.pressed or Label.pressed
        fn()
    end
    if (ovr.colorHovered or Label.colorHover) and face:widgetHovered(splat) then
        color = ovr.colorHovered or Label.colorHover
        if (ovr.colorActive or Label.colorActive) and face:widgetConfirmDown() and face.age >= 2 then
            color = ovr.colorActive or Label.colorActive
        end
    end

    face:widgetDraw(splat, fnt, txt, color)
end

return Label