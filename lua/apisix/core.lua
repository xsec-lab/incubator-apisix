--
-- Licensed to the Apache Software Foundation (ASF) under one or more
-- contributor license agreements.  See the NOTICE file distributed with
-- this work for additional information regarding copyright ownership.
-- The ASF licenses this file to You under the Apache License, Version 2.0
-- (the "License"); you may not use this file except in compliance with
-- the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
local log = require("apisix.core.log")
local local_conf = require("apisix.core.config_local").local_conf()

local config_center = local_conf.apisix and local_conf.apisix.config_center
        or "etcd"
log.info("use config_center: ", config_center)

return {
    version = require("apisix.core.version"),
    log = log,
    config = require("apisix.core.config_" .. config_center),
    json = require("apisix.core.json"),
    table = require("apisix.core.table"),
    request = require("apisix.core.request"),
    response = require("apisix.core.response"),
    lrucache = require("apisix.core.lrucache"),
    schema = require("apisix.schema_def"),
    ctx = require("apisix.core.ctx"),
    timer = require("apisix.core.timer"),
    id = require("apisix.core.id"),
    utils = require("apisix.core.utils"),
    etcd = require("apisix.core.etcd"),
    http = require("apisix.core.http"),
    tablepool = require("tablepool"),

    -- 自定义的文件，放到独立的目录中是为了升级apisix方便
    redis = require("exchange-sec-gateway.core.redis"),
    strings = require("exchange-sec-gateway.core.stringy"),
}
