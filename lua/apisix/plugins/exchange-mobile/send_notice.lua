---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by hartnett.
--- DateTime: 2019/11/8 14:23
---

local string = require("string")
local http = require("resty.http")
local core = require("apisix.core")
local redis = require("apisix.core.redis")

local fetch_local_conf = require("apisix.core.config_local").local_conf
local config = fetch_local_conf()

local notice_api = config.api.notice_api
local active_url = config.api.mobile_active

-- 调用restful api发送激活通知消息
local function send_notice(phone, content, username, device_id, code, src_ip)
    local header, err = ngx.req.get_headers()
    local user_agent = header["user-agent"]

    local data = string.format("phone=%s&content=%s&username=%s&device_id=%s&code=%s&src_ip=%s",
            phone, content, username, device_id, code, src_ip)

    local headers = { ["Content-Type"] = "application/x-www-form-urlencoded", ["Content-Length"] = #data, }

    local http_client = http.new()
    local res, err = http_client:request_uri(notice_api, {
        method = "POST",
        body = data,
        headers = headers,
    })

    if err == nil and res ~= nil and res.status == 200 then
        core.log.warn(string.format("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s",
                "active_sync_send_sms", ngx.localtime(), username, src_ip, device_id, user_agent, phone, code, true))
    end
end

-- 生成激活通知内容
local function generate_content(username, device_id, code, src_ip, device_type, phone_num)
    local content = ""
    if #phone_num > 5 then
        content = string.format("您的邮箱账户 %s 正在一台新的设备（%s，手机号码为：%s）上登录，\n请点击链接查看详情并确定是否允许或拒绝： %s%s （此链接30分钟后失效）\n",
                username, device_type, phone_num, active_url, code)
    else
        content_cn = string.format("您的邮箱账户 %s 正在一台新的设备（%s）上登录，\n请点击链接查看详情并确定是否允许或拒绝，%s%s （此链接30分钟后失效）\n",
                username, device_type, active_url, code)
    end

    return content
end


-- 判断是否需要调用短信接口通知用户激活设备
-- 24小时内只发送5次激活码，每次发送激活码的时间间隔为5分钟
local function send_active_code(username, device_id, phone, code, src_ip, device_type, phone_imei, phone_num)
    local status = true
    local key = string.format("sms_%s_%s_%s", username, device_id, phone)
    local redis_cli = redis.new()
    local res, err = redis_cli:hmget(key, "times", "send_time")
    local times = 1
    local send_time = ngx.now()

    if res ~= nil and type(res[1]) == "string" then
        times = tonumber(res[1])
        send_time = res[2] or 0
        local now = ngx.now()

        -- 不限制次数了，只限制频率
        if now - send_time > 60 * 5 then
            times = times + 1
            send_time = now
            redis_cli:hmset(key, "times", times, "send_time", send_time, "src_ip", src_ip)
            local content = generate_content(username, device_id, code, src_ip, device_type, phone_num)

            send_notice(phone, content, username, device_id, code, src_ip)

        else
            -- 频率太快，返回false
            status = false
        end
    else
        redis_cli:hmset(key, "times", times, "send_time", send_time, "src_ip", src_ip, "last_code", code)

        local content = generate_content(username, device_id, code, src_ip, device_type, phone_num)

        send_notice(phone, content, username, device_id, code, src_ip)
    end
    return status
end


-- 重置激活码状态，方便在激活码使用之后还可以再次激活
local function reset_status(username, device_id, phone)
    local key = string.format("sms_%s_%s_%s", username, device_id, phone)
    local redis_cli = redis.new()
    redis_cli:del(key)
end

local _M = {
    send_active_code = send_active_code,
    reset_status = reset_status,
}

return _M
