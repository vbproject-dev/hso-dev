local ItemCategory    = require "modules.game.items.ItemCategory"
local Equipment       = require "modules.game.items.Equipment"
local Potion          = require "modules.game.items.Potion"
local Material        = require "modules.game.items.Material"

local InventoryHelper = {}

function InventoryHelper.transfer(from, to, itemId, category, quantity)
    local item

    if category == 4 or category == 7 then
        item = from:findById(itemId, category)

        if not item then
            return false
        end

        if quantity < 1 then
            return false
        end
    else
        item = from:get(itemId, category)

        if not item then
            return false
        end
    end

    return from:transferTo(to, item, math.min(item.quantity, quantity))
end

function InventoryHelper.createItem(data)
    local item
    if data.category == ItemCategory.EQUIPMENT then
        item = Equipment.new(data)
    elseif data.category == ItemCategory.POTION then
        item = Potion.new(data)
    elseif data.category == ItemCategory.MATERIAL then
        item = Material.new(data)
    end

    return item
end

return InventoryHelper
