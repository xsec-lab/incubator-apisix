## Note

开源版本不支持以下功能：
* redis cluster
* exchange-ews插件


## 需要的一些函数

```lua
-- wbxml string to  table
-- MIX 2||imei||MIX 2||+phone_num||中国联通 (46001)
local function wbxml2info(wbxml)
    local info = {}
    if #wbxml > 10 then
        local ret = stringy.split(wbxml, "||") or {}
        if #ret > 0 then
            info["model"] = ret[1]
            info["imei"] = ret[2]
            info["phone"] = ret[4]
        end
    end
    return info
end
```

## 以下几个不需要实现

* core.request.get_ip()
* ua = core.request.header("user-agent")
* client_type=core.strings.split(ua,"/")


## 需要实现的几个

* send_active_code，发送激活码
* reset_send_active_status，重置发送激活码的状态
* generate_content，生成发送内容，不考虑双语了
* mobole.lua中的功能要实现
* basic_auth.lua中的功能要实现
* active_code.lua中的内容要实现


**注意事项**

* `mobile.lua`中的`get_wbxml_data`返回值改为json吧，现在是||分割的字符串，其实用json更加方便，需要修改一下go的接口，返回一个json，而不是以||分割的string了。

* 先实现上面的几个逻辑，最后实现`device.lua`
* device.lua中的逻辑需要修改数据库结构了，而且不支持redis cluster了，之前为了兼容JAVA版本的，历史包袱太多，导致代码非常不优雅

* 最新的lua版本的数据结构与golang版本的相兼容吧，这样go的激活逻辑就可以复用了，不用额外再搞新的激活逻辑了，激活逻辑需要并入到echo中，目前是用原生的net/http包写的

* 看看`apisix`官方如何连接redis的，直接在配置文件中加入redis的配置，然后用`core.config_local读取`

