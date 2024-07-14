local mth = require "cnd.mth"
---@diagnostic disable: cast-local-type

---@class cnd.ui.label
---@field color number[] The label color
---@field colorHover number[]|nil The label color, if hovered.
---@field colorActive number[]|nil The label color, if hovered and pressed.
---@field pressed function What happens when pressed.
---@field font love.Font The draw value, supports anything that can be drawn by the ui.
local label = {}

label.color = {1.0, 1.0, 1.0, 1.0}
label.text = "Default Text"
---@type number|nil
label.maxWidth = nil
---@type "left"|"center"|"right"|"justify"
label.align = "left"
label.pressed = function() end

---@param face cnd.ui.layout
---@param ovr table
label.layout = function(face, ovr)
    local mw = ovr.maxWidth or label.maxWidth
    local fnt = ovr.font or label.font or face.parent.defaultFont
    local txt = ovr.text or label.text
    local color = ovr.color or label.color
    if mw == nil or mw < 1.0 then
        local splat = mth.rec(0, 0, fnt:getWidth(txt), fnt:getHeight())
        if face:widgetClicked(splat) then
            local fn = ovr.pressed or label.pressed
            fn()
        end
        if (ovr.colorHovered or label.colorHover) and face:widgetHovered(splat) then
            color = ovr.colorHovered or label.colorHover
            if (ovr.colorActive or label.colorActive) and face:widgetConfirmDown() and face.age >= 2 then
                color = ovr.colorActive or label.colorActive
            end
        end
        face:widgetDraw(splat, fnt, txt, color)
        return
    end

    local hsh = love.data.hash("md5", txt)
    local current = face:widgetGetState("label_hash", "")
    if hsh ~= current then
        face:widgetSetState("label_hash", hsh)
        local new_cache = love.graphics.newText(fnt, txt)
        new_cache:setf(txt, mw, ovr.align or label.align)
        face:widgetSetState("label_cache", new_cache)
    end
    ---@type love.Text
    local cache = face:widgetGetState("label_cache")
    local w, h = cache:getDimensions()
    local rec = mth.rec(0,0,w,h)

    if face:widgetClicked(rec) then
        local fn = ovr.pressed or label.pressed
        fn()
    end
    if (ovr.colorHovered or label.colorHover) and face:widgetHovered(rec) then
        color = ovr.colorHovered or label.colorHover
        if (ovr.colorActive or label.colorActive) and face:widgetConfirmDown() and face.age >= 2 then
            color = ovr.colorActive or label.colorActive
        end
    end
    face:widgetDraw(rec, cache, nil, color)
end

return label