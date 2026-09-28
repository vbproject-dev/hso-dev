local CommonWritter = require("modules.writters.CommonWritter")
local GameWritter = require("modules.writters.GameWritter")
local Menu = require "modules.game.menu.Menu"

return {
    onTalk = function(player, zone, npcId)
        local currentMap = player:getMap().id

        local function addTeleport(menu, name, mapId, x, y)
            if currentMap ~= mapId then
                menu:add(name, function()
                    player:teleport(mapId, x, y)
                end)
            end
        end

        local menu = Menu.new("Teleport")

        local kota = menu:add("Kota")
        addTeleport(kota, "Desa Srigala", 1, 480, 360)
        addTeleport(kota, "Kota Harta Karun", 33, 432, 480)
        addTeleport(kota, "Kota Pelabuhan", 67, 576, 222)
        addTeleport(kota, "Kota Musim Dingin", 93, 498, 336)

        local lainya = menu:add("Lainnya")
        if npcId == -10 then
            addTeleport(lainya, "Gua Api", 4, 888, 672)
            addTeleport(lainya, "Hutan Ilusi", 5, 1026, 882)
            addTeleport(lainya, "Lembah Misterius", 8, 834, 156)
            addTeleport(lainya, "Danau Kenangan", 9, 1243, 876)
            addTeleport(lainya, "Pesisir", 11, 192, 264)
            addTeleport(lainya, "Jurang Batu", 12, 240, 732)
            addTeleport(lainya, "Karang Tersembunyi", 13, 150, 979)
            addTeleport(lainya, "Rawa", 15, 469, 1093)
            addTeleport(lainya, "Kuil Kuno", 16, 673, 1093)
            addTeleport(lainya, "Gua Kelalawar", 17, 660, 612)
        elseif npcId == -33 then
            addTeleport(lainya, "Gurun", 20, 787, 966)
            addTeleport(lainya, "Jurang Tengelam", 22, 120, 678)
            addTeleport(lainya, "Kuburan Pasir", 24, 576, 222)
            addTeleport(lainya, "Mata Air Hantu", 26, 576, 222)
            addTeleport(lainya, "Makam Lt1", 29, 576, 222)
            addTeleport(lainya, "Makam Lt2", 30, 360, 624)
            addTeleport(lainya, "Makam Lt3", 31, 360, 624)
            addTeleport(lainya, "Daratan Tinggi", 37, 150, 674)
            addTeleport(lainya, "Tebing Curam", 39, 199, 882)
            addTeleport(lainya, "Dunia Atas", 41, 187, 462)
            addTeleport(lainya, "Bawah Tanah", 43, 228, 43)
            addTeleport(lainya, "Gerbang Dunia Bawah", 45, 576, 222)
            addTeleport(lainya, "Mataram", 103, 462, 990)
            addTeleport(lainya, "Gua Kelalawar", 17, 660, 612)
        elseif npcId == -55 then
            addTeleport(lainya, "Labirin", 74, 246, 354)
            addTeleport(lainya, "Labirin Lt3", 77, 132, 270)
            addTeleport(lainya, "Lembah Es", 94, 324, 240)
            addTeleport(lainya, "Kaki Gunung Salju", 95, 479, 128)
            addTeleport(lainya, "Celah Es", 96, 193, 606)
        end
        player.menu = menu
        GameWritter.openMenu(player, menu)
    end
}
