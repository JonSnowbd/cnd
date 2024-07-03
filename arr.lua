local obj = require "cnd.obj"

---@class cnd.arr: cnd.obj
---@field items any[]
local arr = obj:extend()

function arr:new()
    self.items = {}
end

---@generic T
---@param sortFn fun(left: T, right: T): boolean
function arr:sort(sortFn)
    table.sort(self.items, sortFn)
end

--- Adds an item into the end of the array.
---@generic T
---@param item T
function arr:append(item)
    self.items[#self.items+1] = item
end

--- Removes element at index. Leaves no hole.
---@param index integer
function arr:remove(index)
    local count = #self.items
    for i=index,count do
        if i >= count then
            self.items[i] = nil
            return
        end
        self.items[i] = self.items[i+1]
    end
end

--- Returns true if the item exists in this arr.
---@generic T
---@param item T
---@return boolean
function arr:has(item)
    for i=1,#self.items do
        if self.items[i] == item then return true end
    end
    return false
end

--- Removes a specific item from the arr. Uses equality check `==`
---@generic T
---@param item T
function arr:removeItem(item)
    for i=1,#self.items do
        if self.items[i] == item then
            self:remove(i)
            return
        end
    end
end

--- Removes items if `keep(item)` returns false.
---@generic T
---@param keep fun(item: T): boolean
function arr:filter(keep)
    local new = {}
    for i=1,#self.items do
        if keep(self.items[i]) then
            new[#new+1] = self.items[i]
        end
    end
    self.items = new
end

function arr:clear()
    self.items = {}
end

---@return fun(): any
function arr:iter()
    local i = 0
    return function ()
        i = i + 1
        return self.items[i]
    end
end

return arr