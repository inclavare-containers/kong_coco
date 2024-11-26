import json
import base64

def json_to_base64(json_data):
    # 将 JSON 数据转换为字符串
    json_string = json.dumps(json_data)
    
    # 将 JSON 字符串转换为字节
    json_bytes = json_string.encode('utf-8')
    
    # 对字节进行 Base64 编码
    base64_bytes = base64.b64encode(json_bytes)
    
    # 将 Base64 编码的字节转换为字符串
    base64_string = base64_bytes.decode('utf-8')
    
    # 移除 Base64 编码字符串末尾的填充字符 '='
    base64_string_nopadding = base64_string.rstrip('=')
    
    return base64_string_nopadding

# 示例 JSON 数据
json_data = {"svn":"1","report_data":"dGVzdAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=="}

# 对 JSON 数据进行 Base64 编码
base64_encoded = json_to_base64(json_data)

print("原始 JSON 数据:")
print(json_data)
print("Base64 编码后的字符串（不使用填充）:")
print(base64_encoded)
