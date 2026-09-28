require "core.Class"
require "core.Logger"
require "core.Constants"
local ServerManager = require "core.ServerManager"
local Main          = class("Main")


function Main:init()
    DEBUG = true
    ServerManager.instance():init()
end

function Main:onUpdate(dt)
    ServerManager.instance():update(dt)
end

function Main:pollEvents()
    ServerManager.instance():pollEvents()
end

return Main
