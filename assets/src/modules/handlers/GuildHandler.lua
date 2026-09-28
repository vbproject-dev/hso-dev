local Cmd = require "network.Cmd"
local GuildManager = require "modules.game.guild.GuildManager"
local HandlerGuard = require "modules.handlers.HandlerGuard"
local CommonWritter = require "modules.writters.CommonWritter"
local GuildHandler = {}

function GuildHandler.onCreateGuild(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        if GuildManager.getPlayerGuild(player.id) then
            CommonWritter.noticeBox(session, "You are already in a guild")
            return
        end

        if player.gold < 50000 then
            CommonWritter.noticeBox(session, "Not enough gold")
            return
        end

        local guild = GuildManager.create(request.guildName, player.id, player.name, player.level)
        player.gold = player.gold - 50000

        CommonWritter.noticeBox(session, "Guild created: " .. guild.name)
    end)
end

function GuildHandler.onJoinGuild(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        local guild = GuildManager.getGuild(request.guildId)
        if not guild then
            CommonWritter.noticeBox(session, "Guild not found")
            return
        end

        local ok, err = guild:addMember(player.id, player.name, player.level)
        if not ok then
            CommonWritter.noticeBox(session, err)
            return
        end

        CommonWritter.noticeBox(session, "Joined guild: " .. guild.name)
    end)
end

function GuildHandler.onLeaveGuild(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        local guild = GuildManager.getPlayerGuild(player.id)
        if not guild then
            CommonWritter.noticeBox(session, "You are not in a guild")
            return
        end

        local member = guild:getMember(player.id)
        if member and member.role == "leader" then
            CommonWritter.noticeBox(session, "Leader cannot leave")
            return
        end

        guild:removeMember(player.id)
        CommonWritter.noticeBox(session, "Left guild: " .. guild.name)
    end)
end

function GuildHandler.onGetGuildInfo(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        local guild = GuildManager.getPlayerGuild(player.id)
        if not guild then
            CommonWritter.noticeBox(session, "You are not in a guild")
            return
        end

        local data = guild:serialize()
        -- TODO: Send guild info packet to client
    end)
end

function GuildHandler.onUpgradeGuild(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        local guild = GuildManager.getPlayerGuild(player.id)
        if not guild then
            CommonWritter.noticeBox(session, "You are not in a guild")
            return
        end

        local member = guild:getMember(player.id)
        if not member or member.role ~= "leader" then
            CommonWritter.noticeBox(session, "Only leader can upgrade")
            return
        end

        if guild:upgrade() then
            CommonWritter.noticeBox(session, "Guild upgraded to level " .. guild.level)
        else
            CommonWritter.noticeBox(session, "Not enough gold")
        end
    end)
end

function GuildHandler.onDisbandGuild(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        local guild = GuildManager.getPlayerGuild(player.id)
        if not guild then
            CommonWritter.noticeBox(session, "You are not in a guild")
            return
        end

        if guild.leaderId ~= player.id then
            CommonWritter.noticeBox(session, "Only leader can disband")
            return
        end

        GuildManager.deleteGuild(guild.id)
        CommonWritter.noticeBox(session, "Guild disbanded")
    end)
end

return GuildHandler
