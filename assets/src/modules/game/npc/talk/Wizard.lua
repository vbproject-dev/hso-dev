local GameWritter = require("modules.writters.GameWritter")
local Menu = require "modules.game.menu.Menu"
local ShopType = require "modules.game.shop.ShopType"
local ShopService = require "modules.game.shop.ShopService"

return {
    onTalk = function(player, zone, npcId)
        local menu = Menu.new("Item Functions")
        menu:add("Upgrade Item", function()
            player.upgradeState:reset()
            GameWritter.openUI(player, ShopType.SHOP_REBUILD)
        end)
        menu:add("Shop Material", function()
            ShopService.openShop(player, 1)
        end)
        player.menu = menu
        GameWritter.openMenu(player, menu)
    end
}
