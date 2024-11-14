from ehsm import Client

client = Client(base_url="https://8.212.3.169:9000/ehsm", allow_insecure=True)
#appid, apikey = client.enroll()

appid = None  
apikey = None  
# 再次从文件keyid.txt中读取数据到变量keyid中  
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

result = client.generate_quote("Y2hhbGxlbmdl")
#print("challenge is", result.challenge)
print(result.quote)