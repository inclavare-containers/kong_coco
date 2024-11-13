from ehsm import Client
from ehsm.api.enums import KeySpec, Origin, KeyUsage

client = Client(base_url="https://8.212.3.169:9000/ehsm", allow_insecure=True)

appid = None  
apikey = None  
with open('/home/wydx/kong/kong/plugins/api-version/data/appid_apikey.txt', 'r') as file:  
    # 读取文件的每一行  
    lines = file.readlines()  
    # 检查是否至少有两行内容  
    if len(lines) >= 2:  
        # 假设第一行是appid，第二行是apikey  
        appid = lines[0].strip()  # 去除行首行尾的空白字符  
        apikey = lines[1].strip()  # 去除行首行尾的空白字符  
client.set_appid(appid)
client.set_apikey(apikey)

result = client.create_key(
    KeySpec.EH_AES_GCM_128, Origin.EH_INTERNAL_KEY, KeyUsage.EH_KEYUSAGE_ENCRYPT_DECRYPT
)
print(result.keyid)
