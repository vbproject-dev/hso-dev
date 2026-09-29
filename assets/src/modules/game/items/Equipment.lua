local Item = require("modules.game.items.Item")
local GameData = require("database.GameData")
local ItemCategory = require("modules.game.items.ItemCategory")

local Equipment = class("Equipment", Item)

function Equipment:ctor(data)
    Equipment.super.ctor(self, data)
    self.category = ItemCategory.EQUIPMENT
    self.info = GameData.getEquipment(data.id)
    self.options = ArrayList.new(data.options or self.info.option)
    self.plus = data.plus or 0
    self.color = data.color or self.info.color
    self.lock = data.lock or false
    self.expired = data.expired or 0
end

function Equipment.create(data)
    local info = GameData.getEquipment(data.id)
    if not info then return nil end
    return Equipment.new(info)
end

function Equipment:toWearingTable()
    return {
        id = self.id,
        plus = self.plus,
        color = self.color,
        lock = true,
        expired = self.expired,
        options = self.options:toTable()
    }
end

function Equipment:getOptions()
    local stats = ArrayList.new()

    self.options:forEach(function(opt)
        local id = opt.id < 0 and opt.id + 256 or opt.id
        local optData = GameData.getOption(id)

        if optData then
            local value = opt.value


            if optData.percent == 1 then
                local bonus = optData.bonus_upgrade * self.color * 0.2
                value = value + (value * bonus / 100 * self.plus)
            else
                local bonus = optData.bonus_upgrade * self.color
                value = value + (bonus * self.plus)
            end

            stats:add({
                id = id,
                value = value
            })
        end
    end)

    return stats
end

function Equipment:toInventoryTable()
    return {
        category = self.category,
        id = self.id,
        quantity = self.quantity,
        plus = self.plus,
        lock = self.lock,
        color = self.color,
        expired = self.expired,
        options = self.options:toTable()
    }
end

return Equipment
