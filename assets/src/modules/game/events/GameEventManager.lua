local GameEventManager = {
    events = ArrayList.new(),
    active = ArrayList.new(),
}

local function findEvent(collection, id)
    return collection:findFirst(function(event)
        return event.id == id
    end)
end

local function invoke(event, method, ...)
    local callback = event[method]
    if type(callback) ~= "function" then return true end

    local arguments = { ... }
    local success, result = xpcall(function()
        return callback(event, table.unpack(arguments))
    end, debug.traceback)

    if not success then
        log("[GameEventManager] Event '%s' callback '%s' failed:\n%s", event.id, method, result)
        return false
    end

    return result ~= false
end

function GameEventManager.register(event, data)
    if type(event) ~= "table" then return false end

    if data then
        event.config = data
        event.id = event.id or data.id or data.event_id
        event.name = event.name or data.name or event.id
    end

    if not event.id or findEvent(GameEventManager.events, event.id) then
        return false
    end

    GameEventManager.events:add(event)
    return true
end

function GameEventManager.loadModule(moduleName, data)
    local success, event = xpcall(function()
        return require(moduleName)
    end, debug.traceback)

    if not success then
        log("[GameEventManager] Failed to load event module '%s':\n%s", moduleName, event)
        return false
    end

    if not GameEventManager.register(event, data) then
        log("[GameEventManager] Invalid or duplicate event module: %s", moduleName)
        return false
    end

    return true
end

function GameEventManager.loadDatabase(events, modulePrefix)
    if not events then return false end

    local loaded = 0
    events:forEach(function(data)
        local moduleName = data.module_name or data.script_name or data.module
        if moduleName then
            if modulePrefix and not moduleName:find(".", 1, true) then
                moduleName = modulePrefix .. "." .. moduleName
            end

            if GameEventManager.loadModule(moduleName, data) then
                loaded = loaded + 1
            end
        end
    end)

    return loaded > 0
end

function GameEventManager.unregister(id)
    local event = findEvent(GameEventManager.events, id)
    if not event then return false end

    if findEvent(GameEventManager.active, id) then
        GameEventManager.stop(id, "unregister")
    end

    GameEventManager.events:remove(event)
    return true
end

function GameEventManager.get(id)
    return findEvent(GameEventManager.events, id)
end

function GameEventManager.isActive(id)
    return findEvent(GameEventManager.active, id) ~= nil
end

function GameEventManager.start(id, context)
    local event = GameEventManager.get(id)
    if not event or GameEventManager.isActive(id) then return false end

    event.context = context or {}
    if not invoke(event, "onStart", event.context) then return false end

    GameEventManager.active:add(event)
    log("[GameEventManager] Started event: %s", id)
    return true
end

function GameEventManager.stop(id, reason)
    local event = findEvent(GameEventManager.active, id)
    if not event then return false end

    invoke(event, "onStop", reason or "manual")
    GameEventManager.active:remove(event)
    log("[GameEventManager] Stopped event: %s", id)
    return true
end

function GameEventManager.update(dt)
    local failed = ArrayList.new()

    GameEventManager.active:forEach(function(event)
        if not invoke(event, "onUpdate", dt) then
            failed:add(event)
        end
    end)

    failed:forEach(function(event)
        GameEventManager.stop(event.id, "event update failed")
    end)
end

function GameEventManager.dispatch(method, ...)
    local arguments = { ... }

    GameEventManager.active:forEach(function(event)
        if not invoke(event, method, table.unpack(arguments)) then
            log("[GameEventManager] Callback failed: %s.%s", event.id, method)
        end
    end)
end

function GameEventManager.clear()
    local active = GameEventManager.active:toTable()
    for _, event in ipairs(active) do
        GameEventManager.stop(event.id, "clear")
    end

    GameEventManager.events:clear()
end

return GameEventManager
