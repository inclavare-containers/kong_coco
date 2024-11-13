local table = require("table")  
local math = require("math")  
local string = require("string")  
local socket = require("socket.http")  
local ngx = ngx
local time = ngx.time
local base64 = require("base64")  
-- local json = require("json")
-- local hmac = require("hmac")  
-- local url = require("url")  

local cocoas = require "kong.plugins.api-version.cocoas"

local ehsm = {}

-- 自定义的 filter 函数  
function filter(func, seq)  
    local result = {}  
    for i, item in ipairs(seq) do  
        if func(item) then  
            table.insert(result, item)  
        end  
    end  
    return result  
end  
  
-- 自定义的 deepcopy 函数（实现深度复制）  
function deepcopy(orig)  
    local copy = orig -- 递归复制的基准情况  
    if type(orig) ~= "table" then return copy end  
    copy = {}  
    for orig_key, orig_value in next, orig, nil do  
        copy[deepcopy(orig_key)] = deepcopy(orig_value)  
    end  
    setmetatable(copy, getmetatable(orig))  
    return copy  
end  

-- 排序参数并转换为 URL 编码字符串的函数  
function params_sort_str(params)  
    -- 过滤非 nil 的项  
    local items = filter(function(it) return it ~= nil end, params)  
      
    -- 按键排序项，并将其编码为 URL 编码字符串  
    local sorted_items = {}  
    for _, item in ipairs(items) do  
        table.insert(sorted_items, item[0] .. "=" .. (item[1] or ""))  
    end  
    table.sort(sorted_items)  
    local params_str = table.concat(sorted_items, "&")  
    return url.unquote_plus(params_str)  
end  

-- 准备参数的函数，包括时间戳、签名等  
function prepare_params(payload, appid, apikey)  
    -- 对 payload 进行深度复制  
    local payload = deepcopy(payload)  
      
    -- 生成时间戳（以毫秒为单位）  
    -- local timestamp = tostring(math.floor(time.time() * 1000))  
      
    -- 初始化 params 表  
    local params = {}  
    params.appid = appid  
    -- params.timestamp = timestamp  
      
    if payload ~= nil then  
        params.payload = params_sort_str(payload)  
    end  
      
    -- 使用 HMAC-SHA256 生成签名  
    local signature = base64.encode(hmac.digest("sha256", params_sort_str(params) .. apikey, true))  
    params.sign = signature  
    if payload ~= nil then  
        params.payload = payload  
    end  
    return params  
end

function ehsm.test(plugin_conf)
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
    kong.response.set_header(plugin_conf.ehsm_response_in_body, ehsm_id)

    -- 定义要执行的curl命令  
    local curl_command = "curl --insecure https://8.212.3.169:9000/ehsm?Action=Enroll"  
    -- 使用io.popen执行curl命令并将输出打印到stdout  
    local output = io.popen(curl_command):read("*all")  

    -- 使用 Lua 的 string.find 和 string.sub 函数来提取 apikey 和 appid  
    local apikey = output:match("apikey\":\"([^\"]*)")  
    local appid = output:match("appid\":\"([^\"]*)")  
    kong.response.set_header(plugin_conf.ehsm_response_in_body, "generate enroll success")
    kong.response.set_header(plugin_conf.cocoas_response_in_body, appid)

    -- store appid and apikey in db
    -- --[[
    local entity, err = kong.db.keyauth_credentials:insert({
        consumer = { id = "net" },
        key = "secret",
      })
    if not entity then
        kong.log.err("Error when inserting keyauth credential: " .. err)
        return nil
    end
    -- ]]
    
    kong.response.set_header(plugin_conf.ehsm_response_in_body, "insert enroll success")

end


function ehsm.Enroll(plugin_conf)

    
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

function ehsm.GetVersion(plugin_conf)
    -- 定义要执行的curl命令  
    local curl_command = "curl --insecure https://8.212.3.169:9000/ehsm?Action=GetVersion"  
    -- 使用io.popen执行curl命令并将输出打印到stdout  
    local output = io.popen(curl_command):read("*all")  
    kong.response.set_header(plugin_conf.ehsm_response_in_body, output)
end

function ehsm.sdk_ListKey(plugin_conf)
    -- 运行python3 listkey.py指令，并将输出存储到临时文件中  
    local cmd = "python3 /kong/listkey.py"  
    local output = io.popen(cmd):read("*all")  
    print(output)
    kong.response.set_header(plugin_conf.ehsm_response_in_body, output)
end

function ehsm.sdk_GenerateQuote(plugin_conf)
    local cmd = "python3 /home/wydx/kong/kong/plugins/key-auth-modified/ehsm_CLI_generatequote.py"  
    local quote = io.popen(cmd):read("*all")    
    quote = quote:gsub("\n", "") -- 移除quote字符串中所有的换行符  
    local SgxEvidence = '{"quote":"' .. quote .. '"}'
    encodedQuote = base64.encode(SgxEvidence)
    encodedQuote = encodedQuote:gsub("=", "")
    -- 打开文件  
    local file = io.open("/home/wydx/kong/kong/plugins/key-auth-modified/restful-request.json", "w")  
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

function ehsm.AsymmetricEncrypt(plugin_conf)
end

return ehsm
  