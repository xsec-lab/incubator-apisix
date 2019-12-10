## Exchange security gateway

exchange-sec-gateway是一个针对exchange 服务器的安全网关，支持以普通的安全网关模式部署，也具备一键切换到零信任架构的能力（需要根据企业的接口进行对接），它的特性如下：

*	将exchange安全地发布到外网，对外只开放http与https端口，80端口的请求会重定向到443端口，保证传输通道的安全。
* 	可支持通过WEB端、移动设备与电脑客户端访问exchange，并且为这3种访问方式都增加了双因素认证机制。
*	用户可以在脱离VPN的情况下收发邮件，在不可信的网络环境中安全地收发邮件，在保证邮箱账户安全的同时，也能兼顾工作效率与用户体验。


本安全网关基于[apache apisix](https://github.com/apache/incubator-apisix)开发，支持运行在OpenResty 和 Tengine下，详细的安装配置文档请参考apisix的[官方文档](READMD.md)

安全网关的部署与配置请参考配套的技术文章[aaa](bbb)。
