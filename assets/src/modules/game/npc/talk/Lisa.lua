local ShopService = require("modules.game.shop.ShopService")


return {
    onTalk = function(player, zone, npcId)
        ShopService.openShop(player, 0)
    end
}
