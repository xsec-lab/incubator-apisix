---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by hartnett.
--- DateTime: 2019/11/4 00:09
---

local ngx = ngx
local string = string
local check_token = require("apisix.plugins.exchange-owa.check_token")

-- 在POST阶段，判断用户的动态口令是否正确
-- 如果动态口令正确，才将用户名与密码转发到后端邮箱服务器
local function auth_otp_token(mail_server)
    ngx.req.read_body()

    if ngx.var.request_method == "POST" and ngx.var.uri == "/owa/auth.owa" then
        local args, err = ngx.req.get_post_args()
        local exchange_internal = ngx.ctx.exchange_internal or false
        if not exchange_internal then
            local result = check_token.check_token(args.username, args.customToken) or false
            if result then
                ngx.req.set_body_data(ngx.encode_args(args))
            else
                local redirect_url = "/owa/auth/logon.aspx?replaceCurrent=1&reason=2&url=https%3a%2f%2f" .. mail_server .. "%2fowa%2f"
                ngx.redirect(redirect_url)
            end
        end
    end
end



-- 显示登录页面时，替换原始的form，增加动态口令输入框
local function add_otp_token_form()
    if ngx.var.uri == "/owa/auth/logon.aspx" and ngx.var.request_method == "GET" then
        local chunk, eof = ngx.arg[1], ngx.arg[2]
        local buffered = ngx.ctx.buffered
        if not buffered then
            buffered = {}
            ngx.ctx.buffered = buffered
        end

        if chunk ~= "" then
            buffered[#buffered + 1] = chunk
            ngx.arg[1] = nil
        end

        if eof then
            local whole = table.concat(buffered)
            ngx.ctx.buffered = nil

            -- 在默认的登录表单下面增加一个动态口令输入框
            local old_html = "<div class=\"showPasswordCheck signInCheckBoxText\">"
            local new_html = "<div class=\"signInInputLabel\" id=\"passwordLabel\" aria-hidden=\"true\">动态口令:</div><div><input id=\"customToken\" onfocus=\"g_fFcs=0\" name=\"customToken\" value=\"\" type=\"password\" class=\"signInInputText\" aria-labelledby=\"passwordLabel\"></div>"
            whole = string.gsub(whole, old_html, new_html .. old_html)

            ngx.arg[1] = whole
        end
    end
end

local _M = {
    add_otp_token_form = add_otp_token_form,
    auth_otp_token = auth_otp_token,
}

return _M

