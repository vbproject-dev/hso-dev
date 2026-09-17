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

return InventoryHelper
