local GameData       = require "database.GameData"
local Slot           = require "modules.game.items.Slot"
local EquipType      = require "modules.game.items.EquipType"
local DatabaseHelper = {}

function DatabaseHelper.createMonsterDrop()
    local drops = {}

    GameData.equipments:forEach(function(item)
        local allowedSlots = {
            [Slot.WEAPON]   = true,
            [Slot.ARMOR]    = true,
            [Slot.LEG]      = true,
            [Slot.HELMET]   = true,
            [Slot.GLOVE]    = true,
            [Slot.BOOTS]    = true,
            [Slot.NECKLACE] = true,
        }

        GameData.monsters:forEach(function(monster)
            if monster.level >= item.level and monster.level < item.level + 10 and allowedSlots[EquipType.getSlot(item.type)] == true then
                drops[monster.id] = drops[monster.id] or {}

                drops[monster.id][#drops[monster.id] + 1] = {
                    id = item.id,
                    category = 3,
                    rate = 25 - item.color * 5
                }
            end
        end)
    end)

    local MATERIALS = { 0, 1, 2, 3 }
    local POTIONS = { 0, 1, 2, 3, 4, 5 }

    GameData.monsters:forEach(function(monster)
        drops[monster.id] = drops[monster.id] or {}

        for _, id in ipairs(MATERIALS) do
            drops[monster.id][#drops[monster.id] + 1] = {
                id = id,
                category = 7,
                rate = 25
            }
        end

        for _, id in ipairs(POTIONS) do
            drops[monster.id][#drops[monster.id] + 1] = {
                id = id,
                category = 4,
                rate = 30
            }
        end
    end)

    GameData.monsters:forEach(function(monster)
        if drops[monster.id] then
            updateTable("monster", {
                item_drop = JSON.fromTable(drops[monster.id])
            }, {
                id = monster.id
            })
        end
    end)
end

return DatabaseHelper
