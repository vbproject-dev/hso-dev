local ShopService = require("modules.game.shop.ShopService")
local GameWritter = require("modules.writters.GameWritter")

return {
    onTalk = function(player, zone, npcId)
        log("CommonScript onTalk: " .. player.id .. ", " .. zone.id .. ", " .. npcId)

        if npcId == -74 or npcId == -3 then
            ShopService.openShop(player, 0)
        elseif npcId == -45 or npcId == -43 then
            GameWritter.listZone(player, zone:getMap():getZoneStatusList())
        elseif npcId == -7 then
            GameWritter.openStorage(player)
        end
    end
}
