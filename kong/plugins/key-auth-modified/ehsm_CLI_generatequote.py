from ehsm import Client

client = Client(base_url="https://8.212.3.169:9000/ehsm", allow_insecure=True)
appid, apikey = client.enroll()

result = client.generate_quote("Y2hhbGxlbmdl")
#print("challenge is", result.challenge)
print(result.quote)