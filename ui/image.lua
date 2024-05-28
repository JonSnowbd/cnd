---@class Interface.Image
---@field padding number
---@field tint number[] The image color
---@field tintHovered number[]|nil The image color, if hovered.
---@field tintActive number[]|nil The image color, if hovered and pressed.
---@field width number The smallest it can get.
---@field height number The smallest it can get.
---@field pressed function What happens when pressed.
---@field image any The draw value, supports anything that can be drawn by the ui.
---@field data any|nil The draw data. If you passed in an ImageSheet, this would be the draw index, etc.
local Image = {}

Image.padding = 0.0
Image.tint = {1.0, 1.0, 1.0, 1.0}
Image.width = 16.0
Image.height = 16.0
Image.image = true
Image.data = nil
Image.pressed = function() end

---@param face Interface.Layout
---@param ovr table
Image.layout=function(face, ovr)
    local mw = ovr.width or Image.width
    local mh = ovr.height or Image.height

    local p = ovr.padding or Image.padding
    local color = ovr.tint or Image.tint

    local tintH = ovr.tintHovered or Image.tintHovered
    local tintA = ovr.tintActive or Image.tintActive

    if tintH ~= nil and face:widgetHovered(p, p, mw+(p*2), mh+(p*2)) then
        color = tintH
        if tintA ~= nil and face:widgetConfirmDown() and face.age >= 2 then
            color = tintA
        end
    end

    face:widgetDraw(p, p, mw+(p*2), mh+(p*2), ovr.image or Image.image, ovr.data or Image.data, color)
end

return Image