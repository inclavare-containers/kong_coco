from ehsm import Client

client = Client(base_url="https://8.212.3.169:9000/ehsm", allow_insecure=True)
appid, apikey = client.enroll()

# 初始化变量  
keyid = None  
# 打开文件并读取内容  
with open('/home/wydx/kong/kong/plugins/api-version/data/keyid.txt', 'r') as file:  
    # 读取文件的全部内容，这里假设文件中只有一行数据  
    keyid = file.read().strip()   
#print(keyid)
result = client.encrypt("Y2hhbGxlbmdl", keyid, "wydx")
print(result.ciphertext)