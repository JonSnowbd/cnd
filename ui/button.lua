---@class Interface.Button
---@field text string
---@field background any The default background for the button, can be any renderable resource or nil.
---@field minimumWidth number The smallest it can get.
---@field minimumHeight number The smallest it can get.
---@field pressed function What happens when pressed.
local Button = {}

Button.text = "Button"
Button.background = true
--- Background color when unhovered
Button.color = {0.7, 0.7, 0.7, 1.0}
--- Background color when hovered
Button.colorHover = {0.8, 0.8, 0.8, 1.0}
--- Background color when confirm is down
Button.colorActive = {1.0, 1.0, 1.0, 1.0}
Button.font = nil
Button.fontColor = {0.0, 0.0, 0.0, 1.0}
Button.minimumWidth = 8.0
Button.minimumHeight = 8.0
Button.padding = 3.0
Button.pressed=function() end

---comment
---@param ui Interface.Layout
---@param ovr table
Button.layout = function(ui, ovr)
    ---@type love.Font|nil
    local font = ovr.font or Button.font or ui.parent.defaultFont
    if font == nil then error("Button needs a font. Assign override font, button.font, or ui.defaultFont") end

    local p = ovr.padding or Button.padding
    local fw = font:getWidth(ovr.text or Button.text)
    local fh = font:getHeight()

    local col = ovr.color or Button.color

    if ui:widgetHovered(0,0,fw+(p*2),fh+(p*2)) then
        if ui:widgetConfirmDown() then
            col = ovr.colorActive or Button.colorActive
        else
            col = ovr.colorHover or Button.colorHover
        end
    end
    if ui:widgetClicked(0,0,fw+(p*2),fh+(p*2)) and ui.age >= 2 then
        local fn = ovr.pressed or Button.pressed
        fn()
    end

    ui:widgetDraw(0,0,fw+ (p*2), fh+ (p*2), ovr.background or Button.background, nil, col)
    ui:widgetDraw(p,p,fw, fh, font, ovr.text or Button.text, ovr.fontColor or Button.fontColor)
end

return Button