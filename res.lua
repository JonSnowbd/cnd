local json = require "cnd.json"

local res = {}

res.imagesheet = require "cnd.res.imagesheet"
res.ninepatch = require "cnd.res.ninepatch"
res.sprite = require "cnd.res.sprite"

--- Saves data to a path in the save directory, overwriting if exists.
---@param userPath string name of the file in the save directory, eg "settings/player1"
---@param data table The lua data table to be persisted, eg {mileage=10.3} -> {"mileage": 10.3}
---@param tight boolean if true, compresses.
function res.save(userPath, data, tight)
    if userPath ~= nil and userPath ~= "" then
        love.filesystem.createDirectory(userPath)
    end
    if tight then
        local newData = love.data.compress("string", "gzip", json.encode(data))
        love.filesystem.write(userPath, newData)
    else
        local newData = json.encode(data)
        love.filesystem.write(userPath, newData)
    end
end

--- Looks in save directory for the path, and loads it to return as a table,
--- or returns defaultData after persisting the default data to the userPath if it didnt exist.
---@param userPath string name of the file in the save directory, eg "settings/player1"
---@param defaultData table pass in the default settings of the resource, this wont be returned if the file exists.
---@param tight boolean if true, decompresses data.
---@return table
function res.load(userPath, defaultData, tight)
    local exists = love.filesystem.getInfo(userPath, "file") ~= nil
    if exists then
        local data = love.filesystem.read(userPath)
        if tight then
            ---@diagnostic disable-next-line: cast-local-type
            data = love.data.decompress("string", "gzip", data)
        end
        print("DEP: Loading from file '"..userPath.."'")
        ---@diagnostic disable-next-line: param-type-mismatch
        return json.decode(data)
    else
        res.save(userPath, defaultData, tight)
        return defaultData
    end
end

return res