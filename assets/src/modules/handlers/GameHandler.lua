local Cmd              = require "network.Cmd"
local GameWritter      = require "modules.writters.GameWritter"
local GameWorld        = require "modules.game.world.GameWorld"
local CommonWritter    = require "modules.writters.CommonWritter"
local HandlerGuard     = require "modules.handlers.HandlerGuard"
local ShopService      = require "modules.game.shop.ShopService"
local GameData         = require "database.GameData"
local CharacterWritter = require "modules.writters.CharacterWritter"
local ModuleRegistry   = require "core.ModuleRegistry"
local ObjectType       = require "modules.game.entities.ObjectType"
local Combat           = require "modules.game.combat.Combat"
local GameHandler      = {}


function GameHandler.onUseItem(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        local item = player.inventory:get(request.index, 3)

        if not item then
            CommonWritter.noticeBox(session, "Item not found")
            return
        end

        if player:wear(item, request.slot) then
            CharacterWritter.mainCharInfo(player)
            GameWritter.updateInventory(player)
            zone:broadcast(Packet.new(Cmd.CHAR_WEARING, player:wearingData()))
        end
    end)
end

function GameHandler.onUsePotion(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        local item = player.inventory:findById(request.itemId, 4)

        if not item then
            CommonWritter.noticeBox(session, "Item not found")
            return
        end

        local ItemRegistry = require("modules.game.items.function.ItemRegistry")

        local handler = ItemRegistry.get(item.id, 4)
        if not handler then
            CommonWritter.noticeBox(session, "You cannot use this potion")
            return
        end

        if handler(player, item) then
            CharacterWritter.mainCharInfo(player)
            GameWritter.updateInventory(player)
        end
    end)
end

function GameHandler.onMove(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        player:setPosition(request.x, request.y)

        local warp = zone.map:getWarpAt(request.x, request.y)
        if warp then
            local now = os.time()
            if now >= (player.lastWarpTime or 0) then
                player.lastWarpTime = now + 2
                player:setPosition(warp.toX, warp.toY)
                GameWorld.instance():joinMap(player, warp.toMap)
            end
            return
        end

        zone:forEachPlayer(function(other)
            GameWritter.objectMove(other, player)
        end, player)
    end)
end

function GameHandler.onDeleteItem(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        log("delete item: %d %d %d", request.itemId, request.category, request.action)


        local item
        if request.category == 3 then
            item = player.inventory:get(request.itemId, request.category)
        else
            item = player.inventory:findById(request.itemId, request.category)
        end

        if not item then
            CommonWritter.noticeBox(session, "Item not found")
            return
        end

        if request.action == 1 then
            -- sell item
            local GameData  = require "database.GameData"
            local cfg       = GameData.getSetting("config")
            local priceSell = (request.category == 4 or request.category == 7) and
                (cfg.price_sell_potion * item.quantity) or
                (cfg.price_sell_item * item.quantity)
            player:addMoney(0, priceSell)
        end

        if not player.inventory:remove(item) then
            CommonWritter.noticeBox(session, "Failed to delete item")
            return
        end

        GameWritter.updateInventory(player)
    end)
end

function GameHandler.onMonsterInfo(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        local monster = zone:getObject(1, request.id)
        if not monster then
            return
        end

        GameWritter.monsterInfo(player, monster)
    end)
end

function GameHandler.onNpcInfo(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        local NpcScriptRegistry = require("modules.game.npc.NpcScriptRegistry")
        local script = NpcScriptRegistry.get(request.id)
        if script and script.onTalk then
            script.onTalk(player, zone, request.id)
            return
        end
    end)
end

function GameHandler.onBuyItem(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        if not player.shop then
            CommonWritter.noticeBox(session, "You are not in shop")
            return
        end

        ShopService.buyItem(player, request)
    end)
end

function GameHandler.onDynamicMenu(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        local menu = player.menu
        local index = request.index

        if not menu then
            return
        end

        local selected = menu:get(index)

        if not selected then
            return
        end

        if selected:size() > 0 then
            player.menu = selected
            GameWritter.openMenu(player, selected)
            return
        end
        selected:perform(player)
        player.menu = nil
    end)
end

function GameHandler.onMiniGame(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        local Menu = require "modules.game.menu.Menu"
        local EquipType = require "modules.game.items.EquipType"
        local menu = Menu.new("Mini Game")
        menu:add("Add Equipment", function()
            local minLevel = player.level - 50
            local maxLevel = player.level + 10
            local items = GameData.equipments
                :filter(function(item)
                    return (item.role == 5 or item.role == player.class) and (item.level >= minLevel and
                        item.level <= maxLevel) and item.color == 4
                end)

            EquipType.sortItems(items)

            items:forEach(function(item)
                player.inventory:addFrom(item.id, 3)
            end)
            GameWritter.updateInventory(player)
            CommonWritter.noticeBox(session, "Added " .. items:size() .. " equipment")
        end)
        menu:add("Clear inventory", function()
            player.inventory:clear()
            GameWritter.updateInventory(player)
            CommonWritter.noticeBox(session, "Done")
        end)
        player.menu = menu
        GameWritter.openMenu(player, menu)
    end)
end

function GameHandler.onFireMonster(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        local monster = zone:getObject(ObjectType.MONSTER, request.targetId)
        if not monster then
            log("monster not found %d", request.targetId)
            return
        end

        local skill = player.skills:findFirst(function(skill)
            return skill.id == request.skillId
        end)

        if not skill then
            log("skill not found %d", request.skillId)
            return
        end

        if not skill:isLearned() then
            log("skill not learned %d", request.skillId)
            return
        end

        local distance = skill.levelData.castRange
        local targetCount = skill.levelData.targetCount

        if skill:isAttackSkill() then
            if targetCount > 1 then
                local monsters = zone.monsters:filter(function(m)
                    return m:isInDistance(monster, distance)
                end)

                if player:useSkill(skill) then
                    monsters:forEach(function(m)
                        Combat.dealDamageTo(player, m, skill)
                    end)
                end
            else
                if player:useSkill(skill) then
                    Combat.dealDamageTo(player, monster, skill)
                end
            end
        end
    end)
end

function GameHandler.onFirePK(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        local target = zone:getObject(ObjectType.PLAYER, request.targetId)
        if not target then
            log("target not found %d", request.targetId)
            return
        end

        local skill = player.skills:findFirst(function(skill)
            return skill.id == request.skillId
        end)

        if not skill then
            log("skill not found %d", request.skillId)
            return
        end

        if not skill:isLearned() then
            log("skill not learned %d", request.skillId)
            return
        end

        local distance = skill.levelData.castRange
        local targetCount = skill.levelData.targetCount

        if skill:isAttackSkill() then
            if targetCount > 1 then
                local players = zone.players:filter(function(p)
                    return p:isInDistance(target, distance) and p.id ~= player.id
                end)

                if player:useSkill(skill) then
                    players:forEach(function(p)
                        Combat.dealDamageTo(player, p, skill)
                    end)
                end
            else
                if player:useSkill(skill) then
                    Combat.dealDamageTo(player, target, skill)
                end
            end
        end
    end)
end

function GameHandler.onChangeFlag(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        player.typePK = request.type
        zone:forEachPlayer(function(p)
            GameWritter.changeFlag(p, { id = player.id, flag = player.typePK })
        end)
    end)
end

function GameHandler.onCharInfo(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        local targetPlayer = zone:getPlayer(request.id)
        if not targetPlayer then
            return
        end

        CharacterWritter.charInfo(player, targetPlayer)
    end)
end

function GameHandler.onGoHome(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        if request.type == 1 then
            if not player:useMoney(1, 50) then
                CommonWritter.noticeBox(session, "Gem tidak cukup")
                return
            end
            player:recalculateStats()
            local mapId = zone:getMap().id
            GameWorld.instance():joinMap(player, mapId)
        end
    end)
end

function GameHandler.onChangeArea(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        if zone.id == request.zoneId then
            CommonWritter.noticeBox(session, "Kamu sudah berada di area tersebut")
            return
        end

        local newZone = zone:getMap():getZone(request.zoneId)


        if newZone and not newZone:isFull() then
            if newZone.id == zone:getMap():getZoneCount() - 1 then
                if not player:useMoney(1, 150) then
                    CommonWritter.noticeBox(session, "Gem tidak cukup")
                    return
                end

                GameWritter.updateInventory(player)
            end

            newZone:addPlayer(player)
        end
    end)
end

function GameHandler.onUpdateStorage(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        if request.typeAction == -1 then
            GameWritter.updateStorage(player)
            return
        end

        if request.quantity < 1 then
            return
        end

        local InventoryHelper = require("modules.game.inventory.InventoryHelper")
        if request.typeAction == 1 then
            -- transfer from inventory to storage

            log("transfer from inventory to storage %d %d %d", request.itemId, request.category, request.quantity)
            if InventoryHelper.transfer(player.inventory, player.bank, request.itemId, request.category, request.quantity) then
                GameWritter.updateStorage(player)
                GameWritter.updateInventory(player)
            end
        else
            -- transfer from storage to inventory
            log("transfer from storage to inventory %d %d %d", request.itemId, request.category, request.quantity)
            if InventoryHelper.transfer(player.bank, player.inventory, request.itemId, request.category, request.quantity) then
                GameWritter.updateStorage(player)
                GameWritter.updateInventory(player)
            end
        end
    end)
end

return {
    [Cmd.OBJECT_MOVE] = GameHandler.onMove,
    [Cmd.USE_ITEM] = GameHandler.onUseItem,
    [Cmd.DELETE_ITEM] = GameHandler.onDeleteItem,
    [Cmd.MONSTER_INFO] = GameHandler.onMonsterInfo,
    [Cmd.NPC_INFO] = GameHandler.onNpcInfo,
    [Cmd.BUY_ITEM] = GameHandler.onBuyItem,
    [Cmd.DYNAMIC_MENU] = GameHandler.onDynamicMenu,
    [Cmd.MINI_GAME] = GameHandler.onMiniGame,
    [Cmd.USE_POTION] = GameHandler.onUsePotion,
    [Cmd.FIRE_MONSTER] = GameHandler.onFireMonster,
    [Cmd.PK] = GameHandler.onChangeFlag,
    [Cmd.CHAR_INFO] = GameHandler.onCharInfo,
    [Cmd.FIRE_PK] = GameHandler.onFirePK,
    [Cmd.GO_HOME] = GameHandler.onGoHome,
    [Cmd.CHANGE_AREA] = GameHandler.onChangeArea,
    [Cmd.UPDATE_CHAR_CHEST] = GameHandler.onUpdateStorage,
}
