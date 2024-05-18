local current = {}


---@param index string the string you look up in the current translation.
---@param data? table your translations can lookup this data, for example $PRONOUN will look up data["PRONOUN"]
function TR(index, data)
    if current[index] ~= nil then
        local msg = current[index]
        if data ~= nil then
            local work = msg
            for whole, key in string.gmatch(msg, "(\\$([A-Z]+))") do
                work = string.gsub(work, whole, data[key] or ("INVALID KEY: "..key))
            end
            return work
        end
        return msg
    end
end

---@param translationFilePaths string[] the file paths to all the translation files you want to merge.
function SET_TRANSLATION(translationFilePaths)
    current = {}
    local pathCount = #translationFilePaths
    for i=1,pathCount do
        local j = love.filesystem.load(translationFilePaths[i])()
        for k, v in pairs(j) do
            current[k] = v
        end
    end
end