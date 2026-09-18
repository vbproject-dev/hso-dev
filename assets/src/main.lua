require "core.Class"
require "core.Logger"
require "core.Constants"
local SceneManager  = require "gfx.SceneManager"
local ServerManager = require "core.ServerManager"
local Main          = class("Main")


function Main:configure()
    _G.SCREEN_WIDTH = 900  --1280
    _G.SCREEN_HEIGHT = 480 --720
    GFX = false
    return {
        useGraphics = GFX,
        title = "HSO",
        width = SCREEN_WIDTH,
        height = SCREEN_HEIGHT,
    }
end

function Main:init()
    if GFX then
        gfx:setFont(Font.create("fonts/JetBrainsMono-Regular.ttf", FontStyle.BOLD, 16))
        SceneManager.getInstance():setScene(require("gfx.scenes.LogScene").new())
    end
    DEBUG = true
    ServerManager.instance():init()

    -- local result, err = Process.exec("git", {
    --     "status"
    -- })

    -- if not result then
    --     log("Failed to execute git status: " .. tostring(err))
    -- end

    -- log("Git status result: " .. result.stdout)
end

function Main:onUpdate(dt)
    if GFX then
        SceneManager.getInstance():update(dt)
    end

    ServerManager.instance():update(dt)
end

function Main:pollEvents()
    ServerManager.instance():pollEvents()
end

function Main:onRender(g)
    if GFX then
        SceneManager.getInstance():render(g)
    end
end

return Main
