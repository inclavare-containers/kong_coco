from ehsm import Client
import sys 

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
#print(client.appid)
#print(client.apikey)

# 初始化变量  
keyid = None  
# 打开文件并读取内容  
with open('/home/wydx/kong/kong/plugins/api-version/data/keyid.txt', 'r') as file:  
    # 读取文件的全部内容，这里假设文件中只有一行数据  
    keyid = file.read().strip()   
#print("keyid: ",keyid)

# 检查是否提供了足够的参数  
if len(sys.argv) < 3:  
    print("Usage: script_name.py <arg1> <arg2>")  
    sys.exit(1)  
# 获取传入的参数  
aad = sys.argv[1]  
plaintext = sys.argv[2]  
#print("aad: ",aad)
#print("text: ",text)

result = client.encrypt(aad, keyid, plaintext)
print(result.ciphertext)