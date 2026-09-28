local PotionHandler = {}


local function consumeItem(player, item)
    player.inventory:remove(item, 1)
    return true
end

function PotionHandler.healHp(player, item)
    if player.hp >= player.maxHp then
        return false
    end
    player:restoreHp(item.info.value)
    return consumeItem(player, item)
end

function PotionHandler.healMp(player, item)
    if player.mp >= player.maxMp then
        return false
    end
    player:restoreMp(item.info.value)
    return consumeItem(player, item)
end

function PotionHandler.resetAttributes(player, item)
    player:resetAttributes()
    return consumeItem(player, item)
end

function PotionHandler.resetSkills(player, item)
    player:resetSkills()
    return consumeItem(player, item)
end

-- [ITEM_ID] = handler
return {
    [0] = PotionHandler.healHp,
    [1] = PotionHandler.healHp,
    [2] = PotionHandler.healHp,
    [3] = PotionHandler.healMp,
    [4] = PotionHandler.healMp,
    [5] = PotionHandler.healMp,
    [6] = PotionHandler.resetAttributes,
    [7] = PotionHandler.resetSkills,
}
