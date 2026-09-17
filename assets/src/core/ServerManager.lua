local GameServer    = require "network.GameServer"
local WebServer     = require "web.WebServer"
local ServerManager = class("ServerManager")


local instance

function ServerManager.instance()
    if not instance then
        instance = ServerManager.new()
    end

    return instance
end

function ServerManager:ctor()
    self.game = GameServer.new()
    self.web = WebServer.new(self)
end

function ServerManager:init()
    if self.web then self.web:init() end

    self:startServer()
end

function ServerManager:update(dt)
    if self.game then self.game:update(dt) end
end

function ServerManager:pollEvents()
    if self.game then self.game:pollEvents() end
    if self.web then self.web:pollEvents() end
end

function ServerManager:stopServer()
    if self.game then
        self.game:stop()
    end
end

function ServerManager:startServer()
    if self.game then
        self.game:start()
    end
end

function ServerManager:isRunning()
    return self.game:isRunning()
end

return ServerManager
