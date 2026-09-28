local Guild = require("modules.game.guild.Guild")

local GuildManager = {
    guilds = ArrayList.new()
}

function GuildManager.create(guildName, leaderId, leaderName, leaderLevel)
    local guildId = GuildManager:getNextGuildId()

    local guild = Guild.new({
        id = guildId,
        name = guildName,
        leader_id = leaderId
    })

    guild:addMember(leaderId, leaderName, leaderLevel)
    guild:setMemberRole(leaderId, "leader")

    GuildManager.guilds:add(guild)

    return guild
end

function GuildManager.getGuild(guildId)
    return GuildManager.guilds:findFirst(function(guild)
        return guild.id == guildId
    end)
end

function GuildManager.getGuildByName(guildName)
    return GuildManager.guilds:findFirst(function(guild)
        return guild.name == guildName
    end)
end

function GuildManager.getPlayerGuild(playerId)
    return GuildManager.guilds:findFirst(function(guild)
        return guild:getMember(playerId) ~= nil
    end)
end

function GuildManager.deleteGuild(guildId)
    local guild = GuildManager.getGuild(guildId)

    if not guild then
        return false
    end

    GuildManager.guilds = GuildManager.guilds:filter(function(value)
        return value.id ~= guildId
    end)

    return true
end

function GuildManager.getAllGuilds()
    return GuildManager.guilds:toTable()
end

function GuildManager:getNextGuildId()
    local maxId = 0

    self.guilds:forEach(function(guild)
        if guild.id > maxId then
            maxId = guild.id
        end
    end)

    return maxId + 1
end

function GuildManager.load(guildList)
    if not guildList then
        return
    end

    for _, guildData in pairs(guildList) do
        local guild = Guild.new(guildData)
        GuildManager.guilds:add(guild)
    end
end

return GuildManager
