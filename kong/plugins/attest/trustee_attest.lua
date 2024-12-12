local http = require("socket.http")
local json = require("cjson")

local kong = kong

local trustee_attest = {}

function trustee_attest.access(plugin_conf)  
    local headers = kong.request.get_headers()
    local v, api, ng_auth
    for _, name in ipairs(plugin_conf.api) do
        v = headers[name]
        if type(v) == "string" then
            api = v
        end
    end
    for _, name in ipairs(plugin_conf.ng_auth) do
        v = headers[name]
        if type(v) == "string" then
            ng_auth = v
        end
    end

    if api then
        kong.response.set_header(plugin_conf.response_test1, api)
    end
    if ng_auth then
        kong.response.set_header(plugin_conf.response_test2, ng_auth)
    end

    -- 获取 ng_evidence
    local ng_evidence
    local ng_tee = "csv"
    if ng_auth then
        -- 本地变量提供challenge值
        local challenge = "test" 
        local gatewayname = "gateway"
        
        -- send curl
        local url = "http://host.docker.internal:5000/getevidence"
        local payload = string.format([[
        {
            "challenge": "%s",
            "tee": "%s",
            "name": "%s",
            "type": "gateway"
        }
        ]], challenge, ng_tee, gatewayname)
        local response_body = {}
        local res, code, response_headers = http.request{
            url = url,
            method = "POST",
            headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#payload)
            },
            source = ltn12.source.string(payload),
            sink = ltn12.sink.table(response_body)
        }

        -- get response
        local response_data = json.decode(table.concat(response_body))

        -- 提取evidence字段
        ng_evidence = response_data.result.evidence
        kong.response.set_header(plugin_conf.ng_evidence, tostring(ng_evidence))
        kong.response.set_header(plugin_conf.ng_tee, tostring(ng_tee))
    end

    -- 获取 api_evidence
    local my_api_evidence
    local my_api_tee
    local my_api_attest_status
    if api then
        -- send curl
        local url = "http://host.docker.internal:5000/getevidence"
        local payload = string.format([[
        {
            "name": "%s",
            "type": "endpoint"
        }
        ]], api)
        local response_body = {}
        local res, code, response_headers = http.request{
            url = url,
            method = "POST",
            headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#payload)
            },
            source = ltn12.source.string(payload),
            sink = ltn12.sink.table(response_body)
        }

        -- get response
        local response_data = json.decode(table.concat(response_body))

        -- 提取evidence字段
        my_api_attest_status = response_data.result.attest_status

        if my_api_attest_status == "attested" then
            my_api_evidence = response_data.result.evidence
            my_api_tee = response_data.result.tee
            kong.response.set_header(plugin_conf.api_evidence, my_api_evidence)
            kong.response.set_header(plugin_conf.api_tee, my_api_tee)
            kong.response.set_header(plugin_conf.api_attest_status, my_api_attest_status)
        else
            kong.response.set_header(plugin_conf.api_attest_status, my_api_attest_status)
        end
    end
end

return trustee_attest