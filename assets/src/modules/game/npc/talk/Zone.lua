local GameWritter = require("modules.writters.GameWritter")


return {
    onTalk = function(player, zone, npcId)
        GameWritter.listZone(player, zone:getMap():getZoneStatusList())
    end
}
