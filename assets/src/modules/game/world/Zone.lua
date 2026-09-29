local Cmd              = require "network.Cmd"
local CharacterWritter = require "modules.writters.CharacterWritter"
local GameWritter      = require "modules.writters.GameWritter"
local InventoryHelper  = require "modules.game.inventory.InventoryHelper"


local Zone = class("Zone")

function Zone:ctor(map, id, maxPlayers)
    self.map = map
    self.id = id
    self.maxPlayers = maxPlayers or 10
    self.players = ArrayList.new()
    self.monsters = ArrayList.new()
    self.npcs = ArrayList.new()
    self.items = ArrayList.new()
    self.nextDropId = 0
    self.visiblePlayers = {}
    self.visibleMonsters = {}
end

function Zone:getId()
    return self.id
end

function Zone:getMap()
    return self.map
end

function Zone:getPlayers()
    return self.players
end

function Zone:getPlayerCount()
    return self.players:size()
end

function Zone:getMaxPlayer()
    return self.maxPlayers
end

function Zone:isFull()
    return self.players:size() >= self.maxPlayers
end

function Zone:getPlayer(playerId)
    return self.players:findFirst(function(p)
        return p.id == playerId
    end)
end

function Zone:hasPlayer(player)
    if not player then return false end
    return self.players:contains(player)
end

function Zone:addPlayer(player)
    if not player then return false end

    -- If the player is already in another zone, remove them first
    if player.zone then
        player.zone:removePlayer(player)
    end

    player:setZone(self)

    if not self.players:contains(player) then
        self.players:add(player)
    end

    self:onPlayerJoin(player)
    return true
end

function Zone:removePlayer(player)
    if not player then return false end

    if not self.players:contains(player) then
        return false
    end

    self.players:remove(player)
    player:setZone(nil)

    self:onPlayerLeave(player)
    return true
end

function Zone:addMonster(monster)
    if not monster then return false end
    if monster.zone and monster.zone ~= self then monster.zone:removeMonster(monster) end

    monster:setZone(self)

    if not self.monsters:contains(monster) then
        self.monsters:add(monster)
    end

    return true
end

function Zone:removeMonster(monster)
    if not monster or not self.monsters:contains(monster) then return false end

    self.monsters:remove(monster)
    monster:setZone(nil)


    return true
end

function Zone:addNpc(npc)
    if not npc then return false end
    if npc.zone and npc.zone ~= self then npc.zone:removeNpc(npc) end

    npc:setZone(self)

    if not self.npcs:contains(npc) then
        self.npcs:add(npc)
    end

    return true
end

function Zone:removeNpc(npc)
    if not npc or not self.npcs:contains(npc) then return false end

    self.npcs:remove(npc)
    npc:setZone(nil)

    return true
end

function Zone:addItemDrop(item)
    if not item then return false end

    item.id = self.nextDropId
    self.nextDropId = self.nextDropId % 32767 + 1

    self.items:add(item)

    self:forEachPlayer(function(player)
        GameWritter.dropItem(player, item)
    end)

    return true
end

function Zone:removeItemDrop(item)
    if not item then
        return false
    end

    self.items:remove(item)

    -- self:forEachPlayer(function(player)
    --     GameWritter.removeObject(player, item.id)
    -- end)

    return true
end

function Zone:getItemDrop(id)
    return self.items:findFirst(function(item)
        return item.id == id
    end)
end

function Zone:pickItem(player, itemId, category)
    local item = self.items:findFirst(function(item)
        return item.id == itemId and item.category == category
    end)

    if not item or not item:canPick(player.id) then
        return false
    end

    self:removeItemDrop(item)

    local item = InventoryHelper.createItem({
        id = item.itemId,
        category = item.category,
        quantity = item.quantity,
        options = item.options,
    })

    if item then
        player.inventory:add(item)
        return true
    end

    return false
end

function Zone:getObjects(type)
    if type == 0 then return self.players end
    if type == 1 then return self.monsters end
    if type == 2 then return self.npcs end
end

function Zone:getObject(type, id)
    local objects = self:getObjects(type)
    if not objects then return nil end

    return objects:findFirst(function(object) return object.id == id end)
end

function Zone:removeObject(type, id)
    local objects = self:getObjects(type)
    if not objects then return false end

    local object = objects:findFirst(function(object) return object.id == id end)
    if not object then return false end

    objects:remove(object)
    object:setZone(nil)

    return true
end

function Zone:forEachPlayer(callback, exceptPlayer)
    self.players:forEach(function(p)
        if p ~= exceptPlayer then
            callback(p)
        end
    end)
end

function Zone:broadcast(packet, exceptPlayer)
    self:forEachPlayer(function(player)
        player:send(packet)
    end, exceptPlayer)
end

function Zone:update(dt)
    self.monsters:forEach(function(monster)
        if monster.update then
            monster:update(dt)
        end
    end)

    self.players:forEach(function(player)
        if player.update then
            player:update(dt)
        end

        self:updatePlayers(player)
        self:updateMonsters(player)
    end)

    self.items:forEach(function(item)
        item:update(dt)
    end)

    self.items = self.items:filter(function(item)
        return not item:isExpired()
    end)
end

function Zone:isVisible(a, b, range)
    return math.abs(a.x - b.x) < range
        and math.abs(a.y - b.y) < range
end

function Zone:updatePlayers(player)
    local visiblePlayers = self.visiblePlayers[player.id]

    if not visiblePlayers then
        visiblePlayers = {}
        self.visiblePlayers[player.id] = visiblePlayers
    end

    self.players:forEach(function(other)
        if other == player then
            return
        end

        if self:isVisible(player, other, 200) then
            if not visiblePlayers[other.id] then
                visiblePlayers[other.id] = true

                GameWritter.objectMove(player, other)
            end

            return
        end

        if visiblePlayers[other.id] then
            visiblePlayers[other.id] = nil

            GameWritter.removeObject(player, other.id, other.type)
        end
    end)
end

function Zone:updateMonsters(player)
    local visibleMonsters = self.visibleMonsters[player.id]

    if not visibleMonsters then
        visibleMonsters = {}
        self.visibleMonsters[player.id] = visibleMonsters
    end

    self.monsters:forEach(function(monster)
        if monster.isDie then
            return
        end

        if self:isVisible(player, monster, 200) then
            if not visibleMonsters[monster.id] then
                visibleMonsters[monster.id] = true

                GameWritter.objectMove(player, monster)
            end

            return
        end

        if visibleMonsters[monster.id] then
            visibleMonsters[monster.id] = nil

            GameWritter.removeObject(player, monster.id, monster.type)
        end
    end)
end

function Zone:getStatusArea()
    if self:isFull() then
        return 2
    end

    if self:getPlayerCount() >= self.maxPlayers / 2 then
        return 1
    end

    return 0
end

function Zone:onPlayerJoin(player)
    CharacterWritter.mainCharInfo(player)
    GameWritter.changeMap(player)
    GameWritter.npcBig(player, self.npcs)
    self:forEachPlayer(function(other)
        other:send(Packet.new(Cmd.CHAR_WEARING, player:wearingData()))
    end)

    -- GameWritter.itemMap(player, -65, 60, 648, 360, 4, 2, 95)
    -- GameWritter.itemMap(player, -64, 59, 408, 360, 4, 2, 95)
    -- GameWritter.itemMap(player, -62, 61, 528, 360, 3, 2, 75)
    -- GameWritter.itemMap(player, -66, 64, 576, 216, 2, 2, 115)
    -- GameWritter.itemMap(player, -89, 110, 288, 600, 4, 2, 115)
end

function Zone:onPlayerLeave(player)
    self.visiblePlayers[player.id] = nil
    self.visibleMonsters[player.id] = nil
    self:forEachPlayer(function(other)
        GameWritter.leaveMap(other, player.id)
    end)
end

return Zone
