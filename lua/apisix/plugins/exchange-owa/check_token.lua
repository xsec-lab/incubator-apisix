---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by hartnett.
--- DateTime: 2019/11/3 23:35
---

local http = require("resty.http")
local core = require("apisix.core")

-- 从email中获取username
local function get_name_from_email(email)
    local username = ""
    local array_name = core.strings.split(email, "@")
    if #array_name > 0 then
        username = array_name[1]
    end
    return username
end

-- 验证token
local function chk_token(email, token)
    local username = get_name_from_email(email)
    local result = false

    if username == "" then
        return result
    end

    local otp_url = "https://otp.xsec.io/otp/checkSecretKeyOnly"

    local http_cli, err = http.new()
    if err then
        return nil, err
    end

    http_cli:set_timeout(1 * 1000)

    local res
    res, err = http_cli:request_uri(otp_url, {
        method = "POST",
        ssl_verify = false,
        keepalive = false,
        headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded",
        },
        body = string.format("username=%s&verificationCode=%s", username, token)
    })

    if err then
        return nil, err
    end

    if res.status ~= 200 then
        return nil, "invalid response code: " .. res.status
    end

    local ret = core.json.decode(res.body)
    local code = ret["code"] or 0
    local data = ret["data"] or ""

    if code == 200 and data == "success" then
        result = true
    end

    return result

end

local _M = {
    get_name_from_email = get_name_from_email,
    chk_token = chk_token,
}

return _M
