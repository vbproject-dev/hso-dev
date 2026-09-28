local GameWritter = require("modules.writters.GameWritter")


return {
    onTalk = function(player, zone, npcId)
        GameWritter.openStorage(player)
    end
}
