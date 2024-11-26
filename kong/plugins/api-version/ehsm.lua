local table = require("table")
local math = require("math")
local string = require("string")
local socket = require("socket.http")
local ngx = ngx
local time = ngx.time
-- local base64 = require("base64")
-- local json = require("json")
-- local hmac = require("hmac")  
-- local url = require("url")  

local constants = require "kong.constants"
local kong = kong
local cocoas = require "kong.plugins.api-version.cocoas"

local ehsm = {}

function ehsm.access(plugin_conf)
    local headers = kong.request.get_headers()
    local ehsm_id
    -- search in headers
    -- --[[
    for _, name in ipairs(plugin_conf.api_names) do
        local v
        v = headers[name]
        if type(v) == "string" then
            if v == "Enroll" then
                ehsm.Enroll(plugin_conf)
                ehsm.sdk_GenerateQuote(plugin_conf)
                break
            end
            if v == "GetVersion" then
                ehsm.GetVersion(plugin_conf)
                break
            end
            if v == "GenerateQuote" then
                ehsm.sdk_GenerateQuote(plugin_conf)
                break
            end
            if v == "Createkey" then
                ehsm.sdk_Createkey(plugin_conf)
                break
            end
            if v == "ListKey" then
                ehsm.sdk_ListKey(plugin_conf)
                break
            end
            if v == "Encrypt" then
                ehsm.sdk_Encrypt(plugin_conf)
                break
            end
            if v == "Decrypt" then
                ehsm.sdk_Decrypt(plugin_conf)
                break
            end
            if v == "test" then
                ehsm.test(plugin_conf)
                break
            end
        elseif type(v) == "table" then
            -- duplicate API key
            return nil, ERR_DUPLICATE_API_KEY
        end
    end
end

function ehsm.GetVersion(plugin_conf)
    -- 定义要执行的curl命令  
    local curl_command = "curl --insecure https://8.212.3.169:9000/ehsm?Action=GetVersion"
    -- 使用io.popen执行curl命令并将输出打印到stdout  
    local output = io.popen(curl_command):read("*all")
    kong.response.set_header(plugin_conf.ehsm_response_in_body, output)
end

function ehsm.Enroll(plugin_conf)
    -- check if key_names exist
    if type(plugin_conf.key_names) ~= "table" then
        kong.log.err("no conf.key_names set, aborting plugin execution")
        return nil, ERR_INVALID_PLUGIN_CONF
    end
    kong.response.set_header(plugin_conf.ehsm_response_in_body, "get ehsm_id from client success")

    -- get headers
    local headers = kong.request.get_headers()
    local ehsm_id
    -- search in headers
    -- --[[
    for _, name in ipairs(plugin_conf.key_names) do
        local v
        v = headers[name]
      if type(v) == "string" then
        ehsm_id = v
        break
      elseif type(v) == "table" then
        -- duplicate API key
        return nil, ERR_DUPLICATE_API_KEY
      end
    end
    -- ]]
    -- 此处仅获取header，对于header的验证，由于数据库问题，暂时无法验证
    -- kong.response.set_header(plugin_conf.ehsm_response_in_body, ehsm_id)
    
    -- 定义要执行的curl命令  
    local curl_command = "curl --insecure https://8.212.3.169:9000/ehsm?Action=Enroll"
    -- 使用io.popen执行curl命令并将输出打印到stdout  
    local output = io.popen(curl_command):read("*all")

    -- 使用 Lua 的 string.find 和 string.sub 函数来提取 apikey 和 appid  
    local apikey = output:match("apikey\":\"([^\"]*)")
    local appid = output:match("appid\":\"([^\"]*)")
    -- kong.response.set_header(plugin_conf.ehsm_response_in_body, apikey)
    -- kong.response.set_header(plugin_conf.cocoas_response_in_body, appid)
    
    -- 使用数据库替代方案(本地存储)存储enroll密钥
    -- 打开文件  
    local file = io.open("/home/wydx/kong/kong/plugins/api-version/data/appid_apikey.txt", "w")
    if file then
        -- 写入数据  
        file:write(appid .. "\n")  -- 写入appid  
        file:write(apikey .. "\n") -- 写入apikey  
        -- 关闭文件  
        file:close()
    end
    kong.response.set_header(plugin_conf.cocoas_response_in_body, "generate appid-apikey success")

    --[[
    -- 读取数据库密钥
    local newappid
    local newapikey
    local file = io.open("/home/wydx/kong/kong/plugins/api-version/data/appid_apikey.txt", "r")  
    -- 检查文件是否成功打开  
    if file then  
        -- 读取第一行到appid变量  
        newappid = file:read("*line")  
        -- 读取第二行到apikey变量  
        newapikey = file:read("*line")  
        -- 关闭文件  
        file:close()
    end
    -- 打印读取到的值以验证  
    kong.response.set_header(plugin_conf.ehsm_response_in_body, newappid)
    kong.response.set_header(plugin_conf.cocoas_response_in_body, newapikey)
    ]]
end

function ehsm.sdk_GenerateQuote(plugin_conf)
    local cmd = "python3 /home/wydx/kong/kong/plugins/api-version/sdk/ehsm_CLI_generatequote.py"
    local quote = io.popen(cmd):read("*all")
    quote = quote:gsub("\n", "") -- 移除quote字符串中所有的换行符  
    local SgxEvidence = '{"quote":"' .. quote .. '"}'
    encodedQuote = base64.encode(SgxEvidence)
    encodedQuote = encodedQuote:gsub("=", "")
    -- 打开文件  
    local file = io.open("/home/wydx/kong/kong/plugins/api-version/data/restful-request.json", "w")
    if file then
        -- 写入数据  
        file:write("{\n")
        file:write("    \"tee\": \"sgx\",\n")
        file:write("    \"evidence\": \"" .. encodedQuote .. "\",\n")  -- 使用quote的值并用双引号括起来    
        file:write("    \"policy_ids\": []\n")
        file:write("}")
        -- 关闭文件  
        file:close()
        
    end
    
    kong.response.set_header(plugin_conf.ehsm_response_in_body, encodedQuote)
    cocoas.Verify(plugin_conf)
end

function ehsm.sdk_Createkey(plugin_conf)
    -- get headers
    local headers = kong.request.get_headers()
    local v, ehsm_id, text_to_encrypt, aad
    for _, name in ipairs(plugin_conf.key_names) do
        v = headers[name]
        if type(v) == "string" then
            ehsm_id = v
        end
    end
    kong.response.set_header(plugin_conf.ehsm_id, ehsm_id)
    
    -- 运行python3 listkey.py指令，并将输出存储到临时文件中  
    local cmd = "python3 /home/wydx/kong/kong/plugins/api-version/sdk/ehsm_CLI_createkey.py"
    local keyid = io.popen(cmd):read("*all")  
    keyid = keyid:gsub("\n", "") -- 移除keyid字符串中所有的换行符  
    -- 打开文件  
    local file = io.open("/home/wydx/kong/kong/plugins/api-version/data/keyid.txt", "w")
    if file then
        -- 写入数据  
        file:write(keyid .. "\n")  -- 写入appid  
        -- 关闭文件  
        file:close()
    end
    kong.response.set_header(plugin_conf.modified_response, keyid)
end

function ehsm.sdk_ListKey(plugin_conf)
    -- get headers
    local headers = kong.request.get_headers()
    local v, ehsm_id, text_to_encrypt, aad
    for _, name in ipairs(plugin_conf.key_names) do
        v = headers[name]
        if type(v) == "string" then
            ehsm_id = v
        end
    end
    kong.response.set_header(plugin_conf.ehsm_id, ehsm_id)

    -- 运行python3 listkey.py指令，并将输出存储到临时文件中  
    local cmd = "python3 /home/wydx/kong/kong/plugins/api-version/sdk/ehsm_CLI_listkey.py"
    local output = io.popen(cmd):read("*all")
    output = output:gsub("\n", "") -- 移除字符串中所有的换行符  
    print(output)
    kong.response.set_header(plugin_conf.ehsm_response_in_body, output)
end

function ehsm.sdk_Encrypt(plugin_conf)
    -- get headers
    local headers = kong.request.get_headers()
    local v, ehsm_id, text_to_encrypt, aad, key_id
    for _, name in ipairs(plugin_conf.key_names) do
        v = headers[name]
        if type(v) == "string" then
            ehsm_id = v
        end
    end
    for _, name in ipairs(plugin_conf.usr_aad) do
        v = headers[name]
        if type(v) == "string" then
            aad = v
        end
    end
    for _, name in ipairs(plugin_conf.text_to_encrypt) do
        v = headers[name]
        if type(v) == "string" then
            text_to_encrypt = v
        end
    end
    -- 此处仅获取header，对于header的验证，由于数据库问题，暂时无法验证
    kong.response.set_header(plugin_conf.ehsm_id, ehsm_id)
    kong.response.set_header(plugin_conf.text, text_to_encrypt)
    kong.response.set_header(plugin_conf.aad, aad)

    -- 运行python3 listkey.py指令，并将输出存储到临时文件中  
    -- 构建完整的命令字符串，将 text 变量的值作为参数传递  
    local cmd = "python3 /home/wydx/kong/kong/plugins/api-version/sdk/ehsm_CLI_encrypt.py " .. aad .. " " .. text_to_encrypt
    local output = io.popen(cmd,"r"):read("*all")
    output = output:gsub("\n", "") -- 移除字符串中所有的换行符  
    kong.response.set_header(plugin_conf.data_back, output)
    --[[ 
    -- 打开文件  
    local file = io.open("/home/wydx/kong/kong/plugins/api-version/data/encrypted.txt", "w")  
    if file then  
        -- 写入数据  
        file:write(output .. "\n")
        -- 关闭文件  
        file:close()  
    end
    ]]
end

function ehsm.sdk_Decrypt(plugin_conf)
    -- get headers
    local headers = kong.request.get_headers()
    local v, ehsm_id, text_to_encrypt, aad
    for _, name in ipairs(plugin_conf.key_names) do
        v = headers[name]
        if type(v) == "string" then
            ehsm_id = v
        end
    end
    for _, name in ipairs(plugin_conf.usr_aad) do
        v = headers[name]
        if type(v) == "string" then
            aad = v
        end
    end
    for _, name in ipairs(plugin_conf.text_to_decrypt) do
        v = headers[name]
        if type(v) == "string" then
            text_to_decrypt = v
        end
    end
    -- 此处仅获取header，对于header的验证，由于数据库问题，暂时无法验证
    kong.response.set_header(plugin_conf.ehsm_id, ehsm_id)
    kong.response.set_header(plugin_conf.text, text_to_decrypt)
    kong.response.set_header(plugin_conf.aad, aad)

    -- 运行python3 listkey.py指令，并将输出存储到临时文件中  
    local cmd = "python3 /home/wydx/kong/kong/plugins/api-version/sdk/ehsm_CLI_decrypt.py " .. aad .. " " .. text_to_decrypt
    local output = io.popen(cmd):read("*all")
    output = output:gsub("\n", "") -- 移除字符串中所有的换行符  
    kong.response.set_header(plugin_conf.data_back, output)
    --[[
    -- 打开文件  
    local file = io.open("/home/wydx/kong/kong/plugins/api-version/data/decrypted.txt", "w")  
    if file then  
        -- 写入数据  
        file:write(output .. "\n")
        -- 关闭文件  
        file:close()  
    end
    ]]
end

function ehsm.test(plugin_conf)
    kong.response.set_header(plugin_conf.modified_response, "step 1")
    local entity, err = kong.db.keyauth_credentials:insert({
        consumer = { id = "c77c50d2-5947-4904-9f37-fa36182a71a9" },
        key = "secret",
    })
    entity, err = kong.db.keyauth_credentials:update({
        {id = "2b6a2022-770a-49df-874d-11e2bf2634f5" },
        key = "secret" ,
    })
    --kong.response.set_header(plugin_conf.modified_response, "step 2")
    kong.response.set_header(plugin_conf.modified_response, err)
    if not entity then
        kong.response.set_header(plugin_conf.modified_response, "no entity")
    end
    kong.response.set_header(plugin_conf.ehsm_response_in_body, err)
    kong.response.set_header(plugin_conf.modified_response, "insert enroll success")

    -- store appid and apikey in db
    -- seg 2
    --[[
    local entity, err = kong.db.ehsm_credentials:insert({
        ehms_usr_id = ehsm_id,
        apikey = apikey,
        appid = appid
    })
    if not entity then
        kong.log.err("Error when inserting keyauth credential: " .. err)
        kong.response.set_header(plugin_conf.ehsm_response_in_body, err)
        return nil
    end
    kong.response.set_header(plugin_conf.ehsm_response_in_body, "insert enroll success")
    ]]
    -- select an entity from db
    --local entity, err = kong.db.keyauth_credentials:select({
    --    id = ehsm_id
    --})
    --if err then
    --    kong.log.err("Error when inserting keyauth credential: " .. err)
    --    return nil
    --end
    --if not entity then
    --   kong.log.err("Could not find credential.")
    --    return nil
    --end
    --kong.response.set_header(plugin_conf.ehsm_response_in_body, entity.apikey)
    --kong.response.set_header(plugin_conf.cocoas_response_in_body, entity.appid)
end

function ehsm.get_body_example(plugin_conf)
    -- get body
    local body, err
    local v
    for _, name in ipairs(plugin_conf.key_names) do
        body, err = kong.request.get_body()
        v = body[name]
        kong.response.set_header(plugin_conf.modified_response, v)
    end
end

return ehsm