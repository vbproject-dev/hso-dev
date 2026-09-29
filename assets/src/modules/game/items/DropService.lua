local GameData = require "database.GameData"
local ItemDrop = require "modules.game.items.ItemDrop"
local ItemCategory = require "modules.game.items.ItemCategory"
local DropService = {}

function DropService.roll(dropList, category, chance)
    if math.random(1, 1000) > chance then
        return nil
    end

    local drops = dropList:filter(function(item)
        return item.category == category
    end)

    if drops:isEmpty() then
        return nil
    end

    drops:shuffle()

    local roll = math.random(1, 100)
    local rate = 0

    for i = 0, drops:size() - 1 do
        local item = drops:get(i)
        rate = rate + item.rate

        if roll <= rate then
            return item
        end
    end

    return nil
end

function DropService.createDrop(monster, attacker, item)
    local data

    if item.category == ItemCategory.EQUIPMENT then
        data = GameData.getEquipment(item.id)
    elseif item.category == ItemCategory.MATERIAL then
        data = GameData.getMaterial(item.id)
    elseif item.category == ItemCategory.POTION then
        data = GameData.getPotion(item.id)
    end

    if not data then
        return nil
    end

    return ItemDrop.new({
        mobId = monster.id,
        x = monster.x,
        y = monster.y,
        category = item.category,
        itemId = data.id,
        icon = data.icon,
        name = data.name,
        color = data.color,
        quantity = item.quantity or 1,
        options = DropService.randomOptions(data.option) or {},
        ownerId = attacker.id
    })
end

function DropService.randomOptions(options)
    local result = {}

    for _, option in ipairs(options or {}) do
        result[#result + 1] = {
            id = option.id,
            value = math.random(1, option.value)
        }
    end

    return result
end

function DropService.dropItems(monster, attacker)
    local items = ArrayList.new()

    local equipment = DropService.roll(monster.itemDrops, ItemCategory.EQUIPMENT, 10)
    if equipment then
        items:add(DropService.createDrop(monster, attacker, equipment))
    end

    local material = DropService.roll(monster.itemDrops, ItemCategory.MATERIAL, 20)
    if material then
        items:add(DropService.createDrop(monster, attacker, material))
    end

    local potion = DropService.roll(monster.itemDrops, ItemCategory.POTION, 100)
    if potion then
        items:add(DropService.createDrop(monster, attacker, potion))
    end

    return items
end

return DropService
