local CommonWritter    = require "modules.writters.CommonWritter"
local PartManager      = require "database.PartManager"
local Cmd              = require "network.Cmd"
local LoginWritter     = require "modules.writters.LoginWritter"
local CharacterWritter = require "modules.writters.CharacterWritter"
local Md5              = require "utils.Md5"
local LoginHandler     = {}

local GUEST_USER       = "1"
local GUEST_PASS       = "1"

local function createGuestAccount()
    local username, password, account

    repeat
        username = ("guest_%d%04d"):format(os.time(), math.random(0, 9999))
        account = findTable("account", { username = username })
    until not account

    password = ("%08x"):format(math.random(0, 0xFFFFFFFF))

    local id, err = insertTable("account", {
        username = username,
        password = Md5.md5(password),
        create_time = os.date("%Y-%m-%d %H:%M:%S"),
    })

    if not id then
        log("Failed to create guest account: %s", tostring(err))
        return nil
    end

    return findTable("account", { id = id }), password
end

function LoginHandler.onLogin(session, request)
    local user, pass = request.user, request.pass

    local account, err, guestPassword
    if user == GUEST_USER and pass == GUEST_PASS then
        account, guestPassword = createGuestAccount()
        if not account then
            return LoginWritter.loginFail(session, "Failed to create guest account")
        end
    else
        account, err = findTable("account", { username = user })
        if not account then
            return LoginWritter.loginFail(session, "Account not found")
        end

        if not Md5.verifyMD5(pass, account.password) then
            return LoginWritter.loginFail(session, "Incorrect password")
        end
    end

    LoginWritter.saveLogin(session, account.username, guestPassword or pass)

    -- Check if the client needs to receive an update
    local count = PartManager.getPartCount(request.zoom)
    if count ~= request.indexCharPar then
        local parts = PartManager.getAllByZoom(request.zoom):filter(function(part)
            return part.type ~= 113
        end)

        if not CommonWritter.updateData(session, count, parts:size()) then
            return false
        end

        parts:forEach(function(part)
            if not CommonWritter.sendPartData(session, part) then
                return false
            end
        end)
    end

    -- Update the last login and the IP address of the account
    account.ip_address = session:getRemoteAddress():match("^(.-):%d+$")
    account.last_login = os.date("%Y-%m-%d %H:%M:%S")
    local result, updateErr = updateTable("account", {
        ip_address = account.ip_address,
        last_login = account.last_login,
    }, { id = account.id })

    if not result then
        log("Failed to update account: %s", tostring(updateErr))
        return false
    end

    -- Set the session data
    session:set("zoom", request.zoom)
    session:set("account", account)

    log("Zoom %s", tostring(session:get("zoom")))
    return CharacterWritter.selectCharacter(session)
end

return {
    [Cmd.LOGIN] = LoginHandler.onLogin,
}
