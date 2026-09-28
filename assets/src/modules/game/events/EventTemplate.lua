-- Copy this module when creating a new game event.
local EventState = {
    CREATED = 0,
    ACTIVE = 1,
    STOPPED = 2,
}

local EventTemplate = {
    id = "event-template",
    name = "Event Template",
    enabled = true,
    state = EventState.CREATED,
}

function EventTemplate:onStart(context)
    self.context = context or {}
    self.elapsed = 0
    self.state = EventState.ACTIVE
    return true
end

function EventTemplate:onStop(reason)
    self.stopReason = reason or "manual"
    self.context = nil
    self.state = EventState.STOPPED
    return true
end

function EventTemplate:onUpdate(dt)
    if self.state ~= EventState.ACTIVE then return false end


    self.elapsed = self.elapsed + dt
    return true
end

function EventTemplate:onPlayerJoin(player)
    if self.state ~= EventState.ACTIVE then return false end
    if not self.players then self.players = {} end

    self.players[player] = true
    return true
end

function EventTemplate:onPlayerLeave(player)
    if not self.players then return true end

    self.players[player] = nil
    return true
end

return EventTemplate
