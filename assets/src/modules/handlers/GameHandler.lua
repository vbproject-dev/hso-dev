local Cmd              = require "network.Cmd"
local GameWritter      = require "modules.writters.GameWritter"
local GameWorld        = require "modules.game.world.GameWorld"
local CommonWritter    = require "modules.writters.CommonWritter"
local HandlerGuard     = require "modules.handlers.HandlerGuard"
local ShopService      = require "modules.game.shop.ShopService"
local GameData         = require "database.GameData"
local CharacterWritter = require "modules.writters.CharacterWritter"
local ObjectType       = require "modules.game.entities.ObjectType"
local Combat           = require "modules.game.combat.Combat"
local EquipType        = require "modules.game.items.EquipType"
local ItemCategory     = require "modules.game.items.ItemCategory"
local Slot             = require "modules.game.items.Slot"
local ShopType         = require "modules.game.shop.ShopType"
local UpgradeService   = require "modules.game.upgrade.UpgradeService"
local GameHandler      = {}


function GameHandler.onUseItem(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        local item = player.inventory:get(request.index, ItemCategory.EQUIPMENT)

        if not item then
            CommonWritter.noticeBox(session, "Item not found")
            return
        end

        log("SLOT %d", request.slot)

        local slot = EquipType.getSlot(item.info.type)
        if request.slot == Slot.RING_1 or request.slot == Slot.RING_2 then
            slot = request.slot
        end

        if player:wear(item, slot) then
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

        local handler = ItemRegistry.get(item.id, ItemCategory.POTION)
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
                player.isTeleport = 0
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
        if request.category == ItemCategory.EQUIPMENT then
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
            local priceSell = (request.category == ItemCategory.POTION or request.category == ItemCategory.MATERIAL) and
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
        local npc = GameData.getNpc(request.id)
        if npc and npc.script_code then
            local ScriptLoader = require("modules.game.npc.ScriptLoader")
            ScriptLoader.execute(request.id, npc.script_code, "onTalk", player, zone, request.id)
            return
        end

        local NpcScriptRegistry = require("modules.game.npc.NpcScriptRegistry")
        local script = NpcScriptRegistry.get(request.id)
        if script and script.onTalk then
            script.onTalk(player, zone, request.id)
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

        local currentMap = player:getMap().id

        local function addTeleport(menu, name, mapId, x, y)
            if currentMap ~= mapId then
                menu:add(name, function()
                    player:teleport(mapId, x, y)
                end)
            end
        end




        local menu = Menu.new("Mini Game")
        menu:add("Add Equipment", function()
            local minLevel = player.level - 50
            local maxLevel = player.level + 10
            local items = GameData.equipments
                :filter(function(itemData)
                    return (itemData.role == 4 or itemData.role == player.class) and (itemData.level >= minLevel and
                        itemData.level <= maxLevel) and itemData.color > 3
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
        local kota = menu:add("Ke Kota")
        addTeleport(kota, "Desa Srigala", 1, 480, 360)
        addTeleport(kota, "Kota Harta Karun", 33, 432, 480)
        addTeleport(kota, "Kota Pelabuhan", 67, 576, 222)
        addTeleport(kota, "Kota Musim Dingin", 93, 498, 336)
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
                    return not m:isDead() and m:isInDistance(monster, distance)
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

            player.isTeleport = 0
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

function GameHandler.onRebuildItem(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        log("typeAction %d, itemId %d ItemCategory %d", request.typeAction, request.id, request.category)
        if player.uiState == ShopType.SHOP_REBUILD then
            if request.typeAction == 0 then
                local item
                if request.category == ItemCategory.MATERIAL or request.category == ItemCategory.POTION then
                    if not player.upgradeState.item then
                        CommonWritter.noticeBox(session, "Silahkan pilih item terlebih dahulu")
                        return
                    end

                    -- Get Item by itemId
                    item = player.inventory:findById(request.id, request.category)
                    if not item then
                        CommonWritter.noticeBox(session, "Item tidak ditemukan")
                        return
                    end
                    local chance = UpgradeService.getChance(player.upgradeState.item, item) .. "%"

                    player.upgradeState.supportItem = item
                    GameWritter.itemRebuild(player, request.typeAction, request.category, chance, request.id)
                else
                    -- Get Item by inventory index
                    item = player.inventory:get(request.id, ItemCategory.EQUIPMENT)
                    if not item then
                        CommonWritter.noticeBox(session, "Item tidak ditemukan")
                        return
                    end

                    local chance = UpgradeService.getChance(item, player.upgradeState.supportItem) .. "%"

                    player.upgradeState.item = item
                    GameWritter.itemRebuild(player, request.typeAction, request.category, chance, request.id)
                end
            elseif request.typeAction == 2 then
                -- Process the upgrade
                if not player.upgradeState.item then
                    CommonWritter.noticeBox(session, "Silahkan pilih item terlebih dahulu")
                    return
                end

                local cfg = GameData.getSetting("config")
                local materials = ArrayList.new(cfg.upgrade_materials)
                local level = cfg.upgrade_levels[player.upgradeState.item.plus + 1]
                local quantities = ArrayList.new(level.value)

                local valid = true

                materials:forEachIndexed(function(index, id)
                    if index < quantities:size() then
                        local quantity = quantities:get(index)

                        if quantity > 0 and not player.inventory:has(id, ItemCategory.MATERIAL, quantity) then
                            valid = false
                        end
                    end
                end)

                if not valid then
                    CommonWritter.noticeBox(session, "Materials tidak cukup")
                    return
                end


                local upgradePrice = request.category == 0 and level.gold or level.gem

                if not player:useMoney(request.category, upgradePrice) then
                    CommonWritter.noticeBox(session, request.category == 0 and "Gold tidak cukup" or "Gem tidak cukup")
                    return
                end

                -- Reduce require materials from player inventory
                materials:forEachIndexed(function(index, id)
                    if index < quantities:size() then
                        local quantity = quantities:get(index)

                        if quantity > 0 then
                            local item = player.inventory:findById(id, ItemCategory.MATERIAL)
                            player.inventory:remove(item, quantity)
                        end
                    end
                end)

                if player.upgradeState.supportItem then
                    player.inventory:remove(player.upgradeState.supportItem, 1)
                end

                local result = UpgradeService.upgrade(player.upgradeState.item, player.upgradeState.supportItem)
                if result == UpgradeService.Result.SUCCESS then
                    GameWritter.itemRebuild(player, request.typeAction, 3, "Upgrade Berhasil")
                elseif result == UpgradeService.Result.FAIL then
                    GameWritter.itemRebuild(player, request.typeAction, 4, "Upgrade Gagal")
                else
                    CommonWritter.noticeBox(player.session, "Level sudah maksimal")
                end

                GameWritter.updateInventory(player)
            end
        end
        -- local item = player.inventory:getItem(request.itemId, request.category)
        -- if not item then
        --     return
        -- end
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
    [Cmd.REBUILD_ITEM] = GameHandler.onRebuildItem,
}
