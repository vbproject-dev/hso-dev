local LevelSystem = {
    MAX_LEVEL = 130,
    BASE_EXPERIENCE = 150,
    EXPERIENCE_EXPONENT = 2.2
}

function LevelSystem:getRequiredExperience(level)
    return math.floor(self.BASE_EXPERIENCE * level ^ self.EXPERIENCE_EXPONENT)
end

function LevelSystem:canLevelUp(player)
    return player.level < self.MAX_LEVEL
        and player.exp >= self:getRequiredExperience(player.level)
end

return LevelSystem
