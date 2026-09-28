local GameData = {

    settings = ArrayList.new(),
    monsters = ArrayList.new(),
    equipments = ArrayList.new(),
    materials = ArrayList.new(),
    potions = ArrayList.new(),
    options = ArrayList.new(),
    maps = ArrayList.new(),
    itemMapData = ArrayList.new(),
    npcs = ArrayList.new(),
    shops = ArrayList.new(),


    skills = {
        [0] = ArrayList.new(),
        [1] = ArrayList.new(),
        [2] = ArrayList.new(),
        [3] = ArrayList.new()
    }
}

function GameData.load()
    GameData.clear()

    local datasets = {
        { table = "monster",        field = "monsters" },
        { table = "settings",       field = "settings" },
        { table = "item_equipment", field = "equipments" },
        { table = "item_material",  field = "materials" },
        { table = "item_potion",    field = "potions" },
        { table = "item_option",    field = "options" },
        { table = "map_data",       field = "maps" },
        { table = "npc",            field = "npcs" },
        { table = "shop",           field = "shops" },
        { table = "item_map",       field = "itemMapData" },
        { table = "skill",          field = "skills",     groupBy = "role" }

    }

    for _, dataset in ipairs(datasets) do
        local result, err = loadTable(dataset.table)

        if not result then
            log("Failed to load %s: %s", dataset.table, err)
            return false
        end

        if dataset.groupBy then
            result:sort(function(a, b)
                return a.role < b.role
            end)
            result:forEach(function(skill)
                GameData[dataset.field][skill.role]:add(skill)
            end)
        else
            GameData[dataset.field] = result
        end
    end

    return true
end

function GameData.getSetting(name)
    local setting = GameData.settings:findFirst(function(data) return data.name == name end)
    return setting and setting.data
end

function GameData.getEquipment(id)
    return GameData.equipments:findFirst(function(data) return data.id == id end)
end

function GameData.getMaterial(id)
    return GameData.materials:findFirst(function(data) return data.id == id end)
end

function GameData.getPotion(id)
    return GameData.potions:findFirst(function(data) return data.id == id end)
end

function GameData.getNpc(id)
    return GameData.npcs:findFirst(function(data) return data.id == id end)
end

function GameData.getMonster(id)
    return GameData.monsters:findFirst(function(data) return data.id == id end)
end

function GameData.getSkills(role)
    return GameData.skills[role]:reversed()
end

function GameData.getSkillData(role, id)
    return GameData.skills[role]:findFirst(function(data) return data.sid == id end)
end

function GameData.getOption(id)
    return GameData.options:findFirst(function(data) return data.id == id end)
end

function GameData.getShop(id)
    return GameData.shops:findFirst(function(data) return data.id == id end)
end

function GameData.getItemMap(id)
    return GameData.itemMapData:findFirst(function(data) return data.id == id end)
end

function GameData.getItemMapBytes()
    local packet = Packet.new()
    packet:writeShort(GameData.itemMapData:size())
    GameData.itemMapData:forEachIndexed(function(index, itemMap)
        packet:writeShort(itemMap.img_id)
        packet:writeByte(0)
        packet:writeShort(itemMap.x)
        packet:writeShort(itemMap.y)

        packet:writeByte(#itemMap.blocks)
        for __, block in ipairs(itemMap.blocks) do
            packet:writeByte(block.x)
            packet:writeByte(block.y)
        end
    end)

    local Helper = require("utils.Helper")
    local bytes = Helper.stringToTable(packet:getData())

    packet = Packet.new()
    packet:writeShort(#bytes)
    for i = 1, #bytes do
        packet:writeByte(bytes[i])
    end

    return packet:getData()
end

function GameData.getItem(id, category)
    if category == 3 then
        return GameData.getEquipment(id)
    elseif category == 7 then
        return GameData.getMaterial(id)
    elseif category == 4 then
        return GameData.getPotion(id)
    end
end

function GameData.clear()
    GameData.settings:clear()
    GameData.monsters:clear()
    GameData.equipments:clear()
    GameData.materials:clear()
    GameData.potions:clear()
    GameData.options:clear()
    GameData.maps:clear()
    GameData.npcs:clear()
    GameData.shops:clear()

    for _, list in pairs(GameData.skills) do
        list:clear()
    end
end

return GameData
