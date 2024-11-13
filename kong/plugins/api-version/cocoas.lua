
local cocoas = {}

function cocoas.Verify(plugin_conf)
    -- 定义要执行的curl命令  
    local curl_command = "curl -k -X POST http://172.22.0.2:8080/attestation -H 'Content-Type: application/json' -d  @/home/wydx/kong/kong/plugins/api-version/data/restful-request.json"  
    local output = io.popen(curl_command):read("*all")  
    print(output)
    kong.response.set_header(plugin_conf.cocoas_response_in_body, output)
end

function cocoas.empty(plugin_conf)
    kong.response.set_header(plugin_conf.cocoas_response_in_body, "hello_cocoas")
end


return cocoas