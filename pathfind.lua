-- Credit to https://github.com/wesleywerner/lua-star/blob/master/src/lua-star.lua
-- I only adapted it to classic and dep, with appropriate VSC LSP docs.

local interp = require "dep.interp"

---@class Pathfind
local pathfind = {}

--- (Internal) Return the distance between two points.
--- This method doesn't bother getting the square root of s, it is faster
--- and it still works for our use.
--- Overriding is recommended for unique distance cases.
---@param x1 integer
---@param y1 integer
---@param x2 integer
---@param y2 integer
---@return integer
pathfind.distance = function(x1, y1, x2, y2)
  local dx = x1 - x2
  local dy = y1 - y2
  local s = dx * dx + dy * dy
  return s
end

--- (Internal) Return the score of a node.
--- G is the cost from START to this node.
--- H is a heuristic cost, in this case the distance from this node to the goal.
--- Returns F, the sum of G and H.
pathfind.calculateScore = function (previous, node, goal)
    local G = previous.score + 1
    local H = pathfind.distance(node[1], node[2], goal[1], goal[2])
    return G + H, G, H
end

-- (Internal) Returns true if the given list contains the specified item.
local function listContains(list, item)
    for _, test in ipairs(list) do
        if test[1] == item[1] and test[2] == item[2] then
            return true
        end
    end
    return false
end

-- (Internal) Returns the item in the given list.
local function listItem(list, item)
    for _, test in ipairs(list) do
        if test[1] == item[1] and test[2] == item[2] then
            return test
        end
    end
end

-- (Internal) Requests adjacent map values around the given node.
local function getAdjacent(width, height, node, positionIsOpenFunc, includeDiagonals)

    local result = { }

    local positions = {
        { 0, -1 },  -- top
        { -1, 0 },  -- left
        { 0, 1 },   -- bottom
        { 1, 0 },   -- right
    }

    if includeDiagonals then
        local diagonalMovements = {
            { -1, -1 },   -- top left
            { 1, -1 },   -- top right
            { -1, 1 },   -- bot left
            { 1, 1 },   -- bot right
        }

        for _, value in ipairs(diagonalMovements) do
            table.insert(positions, value)
        end
    end

    for _, point in ipairs(positions) do
        local px = interp.clamp(node[1] + point[1], 1, width)
        local py = interp.clamp(node[2] + point[2], 1, height)
        local value = positionIsOpenFunc( px, py )
        if value then
            table.insert( result, {px, py} )
        end
    end

    return result

end

-- Returns the path from start to goal, or false if no path exists.
---@param width integer
---@param height integer
---@param start integer[]
---@param goal integer[]
---@param positionIsOpenFunc fun(x: integer, y: integer):boolean a callback, if it returns true, a cell is considered walkable.
---@param excludeDiagonalMoving boolean
---@return integer[][]|false
function pathfind.find(width, height, start, goal, positionIsOpenFunc, excludeDiagonalMoving)

    local success = false
    local open = { }
    local closed = { }

    ---@type table
    local beginning = {start[1], start[2]}

    beginning.score = 0
    beginning.G = 0
    beginning.H = pathfind.distance(beginning[1], beginning[2], goal[1], goal[2])
    beginning.parent = {0, 0}
    table.insert(open, beginning)

    while not success and #open > 0 do

        -- sort by score: high to low
        table.sort(open, function(a, b) return a.score > b.score end)

        local current = table.remove(open)

        table.insert(closed, current)

        success = listContains(closed, goal)

        if not success then

            local adjacentList = getAdjacent(width, height, current, positionIsOpenFunc, not excludeDiagonalMoving)

            for _, adjacent in ipairs(adjacentList) do

                if not listContains(closed, adjacent) then

                    if not listContains(open, adjacent) then

                        adjacent.score = pathfind.calculateScore(current, adjacent, goal)
                        adjacent.parent = current
                        table.insert(open, adjacent)

                    end

                end

            end

        end

    end

    if not success then
        return false
    end

    -- traverse the parents from the last point to get the path
    local node = listItem(closed, closed[#closed])
    local path = { }

    while node do

        table.insert(path, 1, {node[1], node[2]} )
        node = listItem(closed, node.parent)

    end

    -- reverse the closed list to get the solution
    return path

end

return pathfind