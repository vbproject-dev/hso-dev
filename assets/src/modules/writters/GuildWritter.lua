local GuildWritter = {}

function GuildWritter.guildInfo(session, guild)
    local packet = Packet.new(Cmd.GUILD_INFO)
    packet:writeNumber(guild.id)
    packet:writeString(guild.name)
    packet:writeNumber(guild.level)
    packet:writeNumber(guild.gold)
    packet:writeNumber(guild.gem)
    packet:writeNumber(guild.leaderId)
    packet:writeNumber(guild:getMemberCount())
    packet:writeNumber(guild.maxMembers)

    session:send(packet)
end

function GuildWritter.memberList(session, guild)
    local packet = Packet.new(Cmd.GUILD_MEMBER_LIST)
    local members = guild:getMembers()
    packet:writeNumber(#members)

    for _, member in ipairs(members) do
        packet:writeNumber(member.playerId)
        packet:writeString(member.name)
        packet:writeNumber(member.level)
        packet:writeString(member.role)
        packet:writeNumber(member.joinedAt)
    end

    session:send(packet)
end

function GuildWritter.guildList(session, guilds)
    local packet = Packet.new(Cmd.GUILD_LIST)
    packet:writeNumber(#guilds)

    for _, guild in ipairs(guilds) do
        packet:writeNumber(guild.id)
        packet:writeString(guild.name)
        packet:writeNumber(guild.level)
        packet:writeNumber(guild:getMemberCount())
        packet:writeNumber(guild.maxMembers)
    end

    session:send(packet)
end

return GuildWritter
