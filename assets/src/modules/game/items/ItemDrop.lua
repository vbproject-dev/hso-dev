local ItemDrop = class("ItemDrop")

function ItemDrop:ctor(data)
    self.id = data.id
    self.x = data.x
    self.y = data.y

    self.mobId = data.id

    self.category = data.category
    self.name = data.name
    self.itemId = data.itemId
    self.icon = data.icon
    self.color = data.color or 0
    self.quantity = data.quantity or 1
    self.options = data.options or {}

    self.ownerId = data.ownerId
    self.ownerTime = 30
    self.lifeTime = 60
end

function ItemDrop:update(dt)
    self.ownerTime = math.max(0, self.ownerTime - dt)
    self.lifeTime = self.lifeTime - dt
end

function ItemDrop:isLocked()
    return self.ownerTime > 0
end

function ItemDrop:isExpired()
    return self.lifeTime <= 0
end

function ItemDrop:canPick(playerId)
    return playerId == self.ownerId or self.ownerTime <= 0
end

return ItemDrop
