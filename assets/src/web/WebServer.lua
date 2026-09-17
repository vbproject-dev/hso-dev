local Config = require("core.Config")
local FileApi = require("web.features.files.FileApi")
local PanelApi = require("web.features.panel.PanelApi")

local WebServer = class("WebServer")

function WebServer:ctor(manager)
    self.server = HttpServer.new()
    self.manager = manager
    self.features = {
        FileApi,
        PanelApi.new(self.manager),
    }
end

function WebServer:init()
    local config = Config.load("config.json")
    if not config then
        return false
    end

    self.server:staticFiles("/", "web")
    self.server:setMaxBodySize(1000000000)
    self.server:setHandler({
        onGet = function(request)
            return self:handle("get", request)
        end,

        onPost = function(request)
            return self:handle("post", request)
        end,

        onPut = function(request)
            return self:handle("put", request)
        end,

        onDelete = function(request)
            return self:handle("delete", request)
        end
    })

    self.server:start(config.web.port)

    return true
end

function WebServer:handle(method, request)
    for _, feature in ipairs(self.features) do
        local handler = feature[method]

        if handler then
            local response = handler(feature, request)

            if response then
                return response
            end
        end
    end
end

function WebServer:pollEvents()
    self.server:pollEvents()
end

return WebServer
