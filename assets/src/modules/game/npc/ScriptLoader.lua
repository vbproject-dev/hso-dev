local ScriptLoader = {
    cache = {} -- [npcId] = handler table
}


function ScriptLoader.load(npcId, source)
    if not source or source == "" or type(source) ~= "string" then
        log("[ScriptLoader] NPC %d invalid source type: %s", npcId, type(source))
        return nil
    end

    local env = setmetatable({}, { __index = _G })
    env.require = require
    env.log = log

    local chunk, err = load(source, "npc_" .. tostring(npcId), "t", env)
    if not chunk then
        log("[ScriptLoader] NPC %d compile error: %s", npcId, err)
        return nil
    end

    local ok, handler = xpcall(chunk, debug.traceback)
    if not ok then
        log("[ScriptLoader] NPC %d runtime error:\n%s", npcId, handler)
        return nil
    end

    if type(handler) ~= "table" then
        log("[ScriptLoader] NPC %d script must return a table", npcId)
        return nil
    end

    ScriptLoader.cache[npcId] = handler
    return handler
end

function ScriptLoader.get(npcId)
    return ScriptLoader.cache[npcId]
end

function ScriptLoader.getOrLoad(npcId, source)
    return ScriptLoader.cache[npcId] or ScriptLoader.load(npcId, source)
end

function ScriptLoader.reload(npcId, source)
    local handler = ScriptLoader.load(npcId, source)
    if not handler then
        return false
    end
    log("[ScriptLoader] NPC %d reloaded", npcId)
    return true
end

function ScriptLoader.execute(npcId, source, callback, ...)
    local handler = ScriptLoader.getOrLoad(npcId, source)
    if not handler then
        return false
    end

    local fn = handler[callback]
    if type(fn) ~= "function" then
        return false
    end

    local ok, err = xpcall(fn, debug.traceback, ...)
    if not ok then
        log("[ScriptLoader] NPC %d %s error:\n%s", npcId, callback, err)
        return false
    end

    return true
end

function ScriptLoader.clear(npcId)
    if npcId then
        ScriptLoader.cache[npcId] = nil
    else
        ScriptLoader.cache = {}
    end
end

return ScriptLoader
