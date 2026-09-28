local Config = require "modules.game.upgrade.UpgradeConfig"

local UpgradeService = {}

UpgradeService.Result = {
    SUCCESS  = "SUCCESS",
    FAIL     = "FAIL",
    MAXLEVEL = "MAXLEVEL",
}
local Result = UpgradeService.Result

local NO_SUPPORT = {}

local function supportOf(supportItem)
    return supportItem and Config.SUPPORTS[supportItem.id] or NO_SUPPORT
end

-- Levels lost on failure: distance to the highest safe level
local function failDrop(level)
    local floor = 0
    for _, safe in ipairs(Config.SAFE_LEVELS) do
        if safe <= level then floor = safe end
    end
    return level - floor
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

    item.plus = level - drop
    return Result.FAIL, drop, insured
end

return UpgradeService
