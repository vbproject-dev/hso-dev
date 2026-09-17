local Config                 = require("core.Config")
local MySQL                  = require("core.MySQL")
local GameData               = require("database.GameData")
local GameWorld              = require("modules.game.world.GameWorld")
local HandlerRegistry        = require("core.HandlerRegistry")
local ModuleRegistry         = require("core.ModuleRegistry")
local NpcScriptRegistry      = require("modules.game.npc.NpcScriptRegistry")
local Cmd                    = require("network.Cmd")
local GameServer             = class("GameServer")

local MAX_PACKETS_PER_SECOND = 15
local BAN_SECONDS            = 60
local MYSQL_PING_INTERVAL    = 60

function GameServer:ctor()
    self.mysqlElapsed = 0
    self.rateLimits = {}
    self.blockedIps = {}
    self.server = TCPServer.new()

    self:init()
end

function GameServer:init()
    local config = Config.load("config.json")
    if not config then
        return false
    end

    -- Initial MYSQL
    local dbCfg = config.database
    local instance, err = MySQL.connect(dbCfg.host, dbCfg.user, dbCfg.password, dbCfg.name, dbCfg.port)
    if err then
        log("[MySQL] " .. tostring(err))
        return false
    end

    if not GameData.load() then
        return false
    end

    GameWorld.instance():init()


    ModuleRegistry.loadPackage("modules.writters")
    ModuleRegistry.loadPackage("modules.game.items.function")

    HandlerRegistry.loadAll({
        { module = "modules.handlers.CommonHandler" },
        { module = "modules.handlers.LoginHandler" },
        { module = "modules.handlers.CharacterHandler" },
        { module = "modules.handlers.GameHandler" },
    })

    if GameData.npcs then
        GameData.npcs:forEach(function(npc)
            if npc.script_name then
                NpcScriptRegistry.load(npc.id, "modules.game.npc." .. npc.script_name)
            end
        end)
    end

    NpcScriptRegistry.loadCommon("modules.game.npc.CommonScript")


    self.server:setPort(config.server.port)
    self.server:useHso()

    self.server:setHandler({
        onConnect = function(session)
            local ip = session:getRemoteAddress():match("^(.-):%d+$")
            log("[Network] %s connected", ip)
        end,

        onMessage = function(session, packet)
            if not self:allowPacket(session) then
                local ip = session:getRemoteAddress():match("^(.-):%d+$")
                log("[Network] Blocking IP %s for packet flooding", ip)
                self:blockIp(ip)

                session:close()
                return
            end

            self:handle(session, packet)
        end,

        onDisconnect = function(session)
            self.rateLimits[session] = nil
            local player = GameWorld.instance():getPlayerBySession(session)
            if player then
                GameWorld.instance():unregisterPlayer(player)
                local saved, err = updateTable("player", player:toTable(), { id = player.id })
                if err then
                    log("[MySQL] Failed to update player %s, %s", player.name, err)
                end
            end
        end,

        onError = function(session, err)
            log("[Network] error from %s reason: %s", session:getRemoteAddress(), tostring(err))
        end
    })
end

function GameServer:pollEvents()
    self.server:pollEvents()
end

function GameServer:update(dt)
    self.mysqlElapsed = self.mysqlElapsed + dt

    if self.mysqlElapsed >= MYSQL_PING_INTERVAL then
        self.mysqlElapsed = 0
        MySQL.instance():ping()
    end

    GameWorld.instance():update(dt)
end

function GameServer:start()
    if self.server:isRunning() then
        return false
    end

    self.server:start()

    return true
end

function GameServer:stop()
    self.server:stop()
    GameWorld.instance():removeAllSessions()
end

function GameServer:allowPacket(session)
    local now = os.time()
    local rate = self.rateLimits[session]

    if not rate then
        rate = {
            count = 0,
            time = now
        }

        self.rateLimits[session] = rate
    end

    if now ~= rate.time then
        rate.time = now
        rate.count = 0
    end

    rate.count = rate.count + 1

    if rate.count > MAX_PACKETS_PER_SECOND then
        return false
    end

    return true
end

function GameServer:blockIp(ip)
    self.blockedIps[ip] = os.time() + BAN_SECONDS
end

function GameServer:isBlocked(ip)
    local expiresAt = self.blockedIps[ip]

    if not expiresAt then
        return false
    end

    if os.time() >= expiresAt then
        self.blockedIps[ip] = nil
        return false
    end

    return true
end

function GameServer:handle(session, packet)
    local command = packet:getCmd()
    local handler = HandlerRegistry.get(command)

    if not handler then
        log("[Network] Unknown command %s", Cmd.getName(command))
        return false
    end

    local PacketReader = ModuleRegistry.get("network.PacketReader")
    local reader = PacketReader[command]
    local request = reader and reader(packet) or {}

    local success, err = xpcall(handler, debug.traceback, session, request)

    if not success then
        log("[Network] Handler error\n  Command: %s\n  Remote: %s\n  Error:\n%s", Cmd.getName(command),
            tostring(session:getRemoteAddress()), err)
        return false
    end

    return true
end

function GameServer:isRunning()
    return self.server:isRunning()
end

return GameServer
