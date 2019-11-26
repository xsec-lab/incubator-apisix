---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by hartnett.
--- DateTime: 2019/11/10 22:11
---

local ngx = ngx
local http = require("resty.http")
local core = require("apisix.core")
local redis = require("apisix.core.redis")

local basic_auth = require("apisix.plugins.exchange-ews.basic_auth")
local ntlm = require("apisix.plugins.exchange-ews.ntlm")

-- 获取客户端的真实IP
local function get_user_srcip(ctx)
    local ip = core.request.get_ip(ctx)
    return ip
end

-- 获取客户端的类型
local function get_client_type(ctx)
    local ua = ""
    local user_agent = core.request.header(ctx, "user-agent")
    local table_ua = core.strings.split(user_agent, "/")

    if #table_ua > 0 then
        ua = table_ua[1]
    end

    return ua
end

-- 在nginx的配置文件中调用
local function get_client_type1()
    local headers = ngx.req.get_headers()
    local user_agent = headers["user-agent"]
    local table_ua = core.strings.split(user_agent, "/")

    if #table_ua > 0 then
        ua = table_ua[1]
    end
    return ua
end

-- 获取用户名
local function get_username(ctx, client_type)
    local username = ""
    if client_type == "MacOutlook" then
        username = core.request.header(ctx, "x-user-identity")
    elseif client_type == "AppleExchangeWebServices" then
        local authorization = core.request.header(ctx, "authorization") or ""
        username = basic_auth.get_username_from_basic_auth(authorization)
        if username == "" then
            username = ntlm.get_username(authorization)
        end
    elseif client_type == "Microsoft Office" then
        username = core.request.header(ctx, "x-user-identity")
        if username == "" then
            local authorization = core.request.header(ctx, "authorization") or ""
            username = ntlm.get_username(authorization)
        end
    elseif client_type == "Mozilla" then
        local authorization = core.request.header(ctx, "authorization") or ""
        username = basic_auth.get_username_from_basic_auth(authorization)
        if username == "" then
            username = ntlm.get_username(authorization)
        end
    elseif client_type == "MSRPC" then
        local authorization = core.request.header(ctx, "authorization") or ""
        username = ntlm.get_username(authorization)
    elseif client_type == "gSOAP" then
        local authorization = core.request.header(ctx, "authorization") or ""
        username = ntlm.get_username(authorization)
    else
        username = core.request.header(ctx, "x-user-identity") or ""
    end

    return username
end

-- 获取邮箱地址前缀
local function get_username_from_mail(email)
    local username = ""
    local email_part = core.strings.split(email, "@")
    if #email_part > 0 then
        username = email_part[1]
    end
    return username
end

-- 检测是否为破解行为
local function check_crack(username)
    local times = 1
    local redis_cli = redis.new()

    local key = string.format("ews_login_%s", username)
    local res, err = redis_cli:hmget(key, "times")
    if err == nil and res ~= nil then
        if type(res[1]) == "string" then
            times = tonumber(res[1])
            if times > 15 then
                ngx.exit(ngx.HTTP_CLOSE)
            else
                times = times + 1
                redis_cli:hmset(key, "times", times)
            end
        end
    else
        redis_cli:hmset(key, "times", times)
        redis_cli:expire(key, 60)
    end
end

local function check_opa_policy(opa_url, user_info)
    local result = false

    local data = core.json.encode(user_info)
    local headers = { ["Content-Type"] = "application/json", ["Content-Length"] = #data }
    local trust_info = {}

    http_client = http.new()
    local http_client = http.new()
    local res, err = http_client:request_uri(opa_url, {
        method = "POST",
        body = data,
        headers = headers,
    })

    if err == nil and res ~= nil and res.status == 200 then
        trust_info = core.json.decode(res.body)
    end

    if next(trust_info) then
        result = trust_info.result.allow
    end

    return result

end

local _M = {
    get_user_srcip = get_user_srcip,
    get_client_type = get_client_type,
    get_client_type1 = get_client_type1,
    get_username = get_username,
    get_username_from_mail = get_username_from_mail,
    check_crack = check_crack,
    check_opa_policy = check_opa_policy,
}

return _M