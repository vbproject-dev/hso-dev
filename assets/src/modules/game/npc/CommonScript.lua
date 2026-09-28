local CommonWritter = require("modules.writters.CommonWritter")

return {
    onTalk = function(player, zone, npcId)
        log("CommonScript onTalk: " .. player.id .. ", " .. zone.id .. ", " .. npcId)
        CommonWritter.noticeBox(player.session, "Belum ada fitur")
    end
}
