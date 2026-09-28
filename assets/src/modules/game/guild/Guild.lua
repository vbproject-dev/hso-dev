local Guild = class("Guild")

function Guild:ctor(data)
    self.id = data.id or 0
    self.name = data.name or ""
    self.level = data.level or 1
    self.gold = data.gold or 0
    self.gem = data.gem or 0
    self.icon = data.icon or 1
    self.leaderId = data.leader_id or 0
    self.members = ArrayList.new(data.members or {})
    self.createdAt = data.created_at or os.time()
    self.maxMembers = self:getMaxMembers()
end

function Guild:addMember(playerId, playerName, playerLevel)
    if self.members:size() >= self.maxMembers then
        return false, "Guild is full"
    end

    if self:getMember(playerId) then
        return false, "Player already in guild"
    end

    self.members:add({
        playerId = playerId,
        name = playerName,
        level = playerLevel,
        joinedAt = os.date("%Y-%m-%d %H:%M:%S"),
        role = "member"
    })

    return true
end

function Guild:removeMember(playerId)
    local member = self:getMember(playerId)

    if not member then
        return false
    end

    self.members = self.members:filter(function(value)
        return value.playerId ~= playerId
    end)

    return true
end

function Guild:getMember(playerId)
    return self.members:findFirst(function(member)
        return member.playerId == playerId
    end)
end

function Guild:setMemberRole(playerId, role)
    local member = self:getMember(playerId)

    if not member then
        return false
    end

    member.role = role
    return true
end

function Guild:getMemberCount()
    return self.members:size()
end

function Guild:addGold(amount)
    if amount <= 0 then
        return false
    end

    self.gold = self.gold + amount
    return true
end

function Guild:removeGold(amount)
    if amount <= 0 or self.gold < amount then
        return false
    end

    self.gold = self.gold - amount
    return true
end

function Guild:addGem(amount)
    if amount <= 0 then
        return false
    end

    self.gem = self.gem + amount
    return true
end

function Guild:removeGem(amount)
    if amount <= 0 or self.gem < amount then
        return false
    end

    self.gem = self.gem - amount
    return true
end

function Guild:upgrade()
    local costGold = self:getUpgradeCost()

    if not self:removeGold(costGold) then
        return false
    end

    self.level = self.level + 1
    self.maxMembers = self:getMaxMembers()

    return true
end

function Guild:getUpgradeCost()
    return self.level * 10000
end

function Guild:getMaxMembers()
    return 10 + (self.level - 1) * 5
end

function Guild:toTable()
    return {
        id = self.id,
        name = self.name,
        level = self.level,
        gold = self.gold,
        gem = self.gem,
        icon = self.icon,
        leader_id = self.leaderId,
        members = self.members:toTable(),
        created_at = self.createdAt
    }
end

return Guild
