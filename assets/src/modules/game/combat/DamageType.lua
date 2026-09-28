local DamageType = {
    PHYSICAL = 0,
    FIRE = 1,
    ICE = 2,
    POISON = 3,
    LIGHTING = 4
}

-- local LOOKUP = {}

-- for damageType, ids in pairs(DamageType) do
--     for _, id in ipairs(ids) do
--         LOOKUP[id] = damageType
--     end
-- end

-- function DamageType.fromValue(id)
--     return LOOKUP[id] or DamageType.PHYSICAL
-- end

return DamageType
