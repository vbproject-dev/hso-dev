local EventState = {
    CREATED = 0,
    ACTIVE = 1,
    STOPPED = 2,
}

local GameEvent = {
    id = "game-event",
    name = "Game Event",
    enabled = true,
    state = EventState.CREATED,
}

function GameEvent:onStart(context)
    self.context = context or {}
    self.startedAt = os.time()
    self.state = EventState.ACTIVE
    return true
end

function GameEvent:onStop(reason)
    self.stopReason = reason or "manual"
    self.context = nil
    self.state = EventState.STOPPED
    return true
end

function GameEvent:onUpdate(dt)
    if self.state ~= EventState.ACTIVE then return false end

    self.elapsed = (self.elapsed or 0) + dt
    return true
end

function GameEvent:onPlayerJoin(player)
    if not self.context then return false end
    if not self.players then self.players = {} end

    self.players[player] = true
    return true
end

function GameEvent:onPlayerLeave(player)
    if not self.players then return true end

    self.players[player] = nil
    return true
end

return GameEvent
