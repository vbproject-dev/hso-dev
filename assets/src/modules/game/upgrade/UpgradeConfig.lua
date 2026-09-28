return {
    MAX_LEVEL = 15,

    -- CHANCE[level] = % to go from +level to +(level+1)
    CHANCE = {
        [0] = 100,
        100,
        100,
        90,
        80,
        70, -- +1  .. +5
        60,
        50,
        40,
        35,
        30, -- +6  .. +10
        25,
        20,
        15,
        12, -- +11 .. +14
    },

    -- Level lost on failure (first tier whose maxLevel >= level)
    FAIL_TIERS = {
        { maxLevel = 5,  drop = 0 },
        { maxLevel = 10, drop = 1 },
        { maxLevel = 14, drop = 2 },
    },


    SUPPORTS = {
        [12] = {
            desc      = "Increase Craft Success rate 30% with 30% insurance (only lose 2 levels if craft fails)",
            bonus     = 30,
            insurance = { chance = 30, maxDrop = 2 },
        },
        [13] = {
            desc      = "Increase Craft Success rate 30% with 30% insurance (only lose 1 level if craft fails)",
            bonus     = 30,
            insurance = { chance = 30, maxDrop = 1 },
        },
        [14] = {
            desc      = "Increase Craft Success rate 30% + 5% to total with 100% insurance (no levels lost if craft fails)",
            bonus     = 35,
            insurance = { chance = 100, maxDrop = 0 },
        },
    },
}
