---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by hartnett.
--- DateTime: 2019/11/10 21:57
---

local fetch_local_conf = require("apisix.core.config_local").local_conf
local config = fetch_local_conf()

local core = require("apisix.core")

-- 添加EWS地址
-- ews_type =0表示自动加入，ews_type=1，表示手动激活加入
-- state=0 表示激活，state=1 表示未激活，state=-1 表示禁用
local function add_ews_address(username, ip, ews_type, state, client_type)
    local key = string.format("%s%s", config.prefix.ews_prefix, username)
    local redis_cli = core.redis.new()
    local now = ngx.now() * 1000
    local expire_time = now + 3600 * 72 * 1000
    local value = { state = state, time = now, expire_time = expire_time, ews_type = ews_type, client_type = client_type }
    local ews_str = core.json.encode(value)
    core.log.warn(string.format("key: %s, ip: %s, value: %s", key, ip, value))
    redis_cli:hmset(key, ip, ews_str)
end

-- EWS白名单续期
local function update_ews_address(username, ip, ews_type, state, client_type)
    local key = string.format("%s%s", config.prefix.ews_prefix, username)
    local now = ngx.now() * 1000
    local expire_time = now + 3600 * 72 * 1000
    local value = { state = state, time = now, expire_time = expire_time, ews_type = ews_type, client_type = client_type }
    local ews_str = core.json.encode(value)

    local redis_cli = core.redis.new()
    redis_cli:hmset(key, ip, ews_str)
end

-- 确定EWS中的某个IP是否注册过("ews_username"中有key为ip的值，不管激活状态，光判断是否主动或被动加入过)
local function get_ews_address(username, ip)
    local ews_str = ""
    local result = false
    local key = string.format("%s%s", config.prefix.ews_prefix, username)
    local redis_cli = core.redis.new()
    local res, err = redis_cli:hmget(key, ip)
    if err == nil and res ~= nil then
        if type(res[1]) == "string" then
            result = true
            ews_str = res[1]
        end
    end
    return result, ews_str
end

-- 禁用EWS地址，给设备忽略功能使用
local function disable_ews_address(username, ip)
    local key = string.format("%s%s", config.prefix.ews_prefix, username)
    local has, ews_str = get_ews_address(username, ip)
    if has then
        local ews_info = core.json.decode(ews_str)
        ews_info["state"] = -1
        local value = core.json.encode(ews_info)
        local redis_cli = core.redis.new()
        redis_cli:hmset(key, ip, value)
        -- redis_cli:expire(key, 3600 * 8)
    end
end

-- 确定是否允许某个PC客户端连接，查看状态，如果state<0，表示禁用。
local function get_ews_address_status(username, ip)
    local result = true
    local key = string.format("%s%s", config.prefix.ews_prefix, username)
    local redis_cli = core.redis.new()
    local res, err = redis_cli:hmget(key, ip)
    if err == nil and res ~= nil then
        if next(res) then
            if type(res[1]) == "string" then
                local ews_info = core.json.decode(res[1])
                core.log.warn(string.format("ews_info: %s, ews_ip_state: %s",
                        res[1], tonumber(ews_info["state"])))
                if tonumber(ews_info["state"]) < 0 then
                    result = false
                end
            end
        end
    end
    return result
end

-- 判断是否允许连接
local function chk_ews_address(username, ip)
    local result = false
    local key = string.format("%s%s", config.prefix.ews_prefix, username)
    local redis_cli = core.redis.new()
    local res, err = redis_cli:hmget(key, ip)
    if err == nil and res ~= nil then
        if next(res) then
            if type(res[1]) == "string" then
                local ews_info = core.json.decode(res[1])
                if tonumber(ews_info["state"]) == 0 then
                    result = true
                end
            end
        end
    end
    return result
end

-- 判断某个用户的ews白名单是否存在
local function exist_ews_address(username)
    local result = false
    local key = string.format("%s%s", config.prefix.ews_prefix, username)
    local redis_cli = core.redis.new()
    local res, err = redis_cli:hvals(key)
    if err == nil and res ~= nil then
        result = true
    end

    return result
end

-- 获取某个用户的所有EWS白名单的IPLIST
local function get_ews_iplist(username)
    local iplist = {}
    local key = string.format("%s%s", config.prefix.ews_prefix, username)
    local redis_cli = core.redis.new()
    local res, err = redis_cli:hkeys(key)
    if err == nil and res ~= nil and type(res) == "table" then
        -- core.log(string.format("key: %s, res: %s, value: %s", key, res, table.concat(res, ",")))
        if next(res) then
            iplist = res
        end
    end

    return iplist
end

-- 刷新IP白名单，清除过期的IP地址
local function refresh_ews_address(username)
    local key = string.format("%s%s", config["PREFIX"]["EWS_PRIFIX"], username)
    local redis_cli = core.redis.new()
    local iplist = get_ews_iplist(username)
    local now = ngx.now() * 1000
    for _, ip in pairs(iplist) do
        local result, ews_str = get_ews_address(username, ip)
        if result then
            local ews_info = core.json.decode(ews_str)
            local expire_time = ews_info["expire_time"] or 0
            if now > tonumber(expire_time) then
                -- core.log(string.format("now: %s, %s's ip:%s's expire time is:%s, delete it", now, username, ip, expire_time))
                redis_cli:hdel(key, ip)
            end
        end
    end
end

-- 获取某用户的所有移动端设备的IP列表
local function get_mobile_iplist(username)
    local iplist = {}
    local ips = get_ews_iplist(username)
    for _, ip in pairs(ips) do
        local result, ews_str = get_ews_address(username, ip)
        if result then
            local ews_info = core.json.decode(ews_str)
            local ews_type = ews_info["ews_type"]
            if 0 == tonumber(ews_type) then
                table.insert(iplist, ip)
            end
        end
    end
    return iplist
end

-- 删除某个用户的EWS白名单
local function remove_ews_address(username, ip)
    local key = string.format("%s%s", config.prefix.ews_prefix, username)
    local redis_cli = core.redis.new()
    redis_cli:hdel(key, ip)
end

local _M = {
    add_ews_address = add_ews_address,
    update_ews_address = update_ews_address,
    get_ews_address = get_ews_address,
    disable_ews_address = disable_ews_address,
    get_ews_address_status = get_ews_address_status,
    chk_ews_address = chk_ews_address,
    exist_ews_address = exist_ews_address,
    get_ews_iplist = get_ews_iplist,
    refresh_ews_address = refresh_ews_address,
    get_mobile_iplist = get_mobile_iplist,
    remove_ews_address = remove_ews_address,
}

return _M
