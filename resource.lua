local Object = require "dep.classic"
local json = require "dep.json"


---@class Resource : Object
local Resource = Object:extend()

function Resource:new(identity)
    love.filesystem.setIdentity(identity)
end


local dirOf = function(filePath)
    return filePath:match("(.*/)")
end

--- Saves data to a path in the save directory, overwriting if exists.
---@param userPath string name of the file in the save directory, eg "settings/player1"
---@param data table pass in the default settings of the resource, this wont be returned if the file exists.
---@param tight boolean if true, compresses.
function Resource:sync(userPath, data, tight)
    local dir = dirOf(userPath)
    love.filesystem.createDirectory(dir)
    if tight then
        local data = love.data.compress("string", "gzip", json.encode(data))
        love.filesystem.write(userPath, data)
    else
        local data = json.encode(data)
        love.filesystem.write(userPath, data)
    end
    print("DEP: Creating '"..userPath.."'")
end
--- Looks in save directory for the path, and loads it to return as a table,
--- or returns defaultData after persisting the default data to the userPath if it didnt exist.
---@param userPath string name of the file in the save directory, eg "settings/player1"
---@param defaultData table pass in the default settings of the resource, this wont be returned if the file exists.
---@param tight boolean if true, decompresses data.
---@return table
function Resource:load(userPath, defaultData, tight)
    local exists = love.filesystem.getInfo(userPath, "file") ~= nil
    if exists then
        local data = love.filesystem.read(userPath)
        if tight then
            ---@diagnostic disable-next-line: cast-local-type
            data = love.data.decompress("string", "gzip", data)
        end
        print("DEP: Loading from file '"..userPath.."'")
        return json.decode(data)
    else
        Resource:sync(userPath, defaultData, tight)
        return defaultData
    end
end



return Resource