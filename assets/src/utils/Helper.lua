local Helper = {}

function Helper.tableToString(data)
    return string.char(table.unpack(data))
end

function Helper.stringToTable(str)
    local data = {}
    for i = 1, #str do data[i] = str:byte(i) end
    return data
end

function Helper.trim(value)
    return value:gsub("[^%w]", "")
end

function Helper.percentToInt(value)
    return math.floor(value * 100 + 0.5)
end

function Helper.intToPercent(value)
    return value / 100
end

return Helper
