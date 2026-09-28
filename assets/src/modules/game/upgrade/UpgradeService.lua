local Config = require "modules.game.upgrade.UpgradeConfig"

local UpgradeService = {}

UpgradeService.Result = {
    SUCCESS  = 3,
    FAIL     = 4,
    MAXLEVEL = -1,
}

local Result = UpgradeService.Result

local NO_SUPPORT = {}

local function supportOf(supportItem)
    return supportItem and Config.SUPPORTS[supportItem.id] or NO_SUPPORT
end

local function failDrop(level)
    for _, tier in ipairs(Config.FAIL_TIERS) do
        if level <= tier.maxLevel then return tier.drop end
    end
    return 0
end

local function rollPercent()
    return math.random() * 100
end

--- Success chance (%) for the next level. Safe for UI preview.
function UpgradeService.getChance(item, supportItem)
    local chance = (Config.CHANCE[item.plus] or 0) + (supportOf(supportItem).bonus or 0)
    return math.min(chance, 100)
end

--- Returns Result, dropped, insured. New level is in item.plus. `roll` is injectable for tests.
function UpgradeService.upgrade(item, supportItem, roll)
    roll = roll or rollPercent
    local level = item.plus

    if level >= Config.MAX_LEVEL then
        return Result.MAXLEVEL
    end

    if roll() < UpgradeService.getChance(item, supportItem) then
        item.plus = level + 1
        return Result.SUCCESS
    end

    local support = supportOf(supportItem)
    local drop    = math.max(failDrop(level) - (support.dropReduction or 0), 0)
    local ins     = support.insurance
    local insured = ins ~= nil and drop > ins.maxDrop and roll() < ins.chance
    if insured then drop = ins.maxDrop end

    drop = math.min(drop, level)
    item.plus = level - drop
    return Result.FAIL, drop, insured
end

return UpgradeService
