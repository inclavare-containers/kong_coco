from ehsm import Client
from ehsm.api.enums import KeySpec, Origin, KeyUsage

client = Client(base_url="https://8.212.3.169:9000/ehsm", allow_insecure=True)
appid, apikey = client.enroll()

ehsm_key = client.create_key(KeySpec.EH_AES_GCM_128, Origin.EH_INTERNAL_KEY, KeyUsage.EH_KEYUSAGE_ENCRYPT_DECRYPT)

result = client.encrypt("Y2hhbGxlbmdl",	ehsm_key.keyid, "cGxhaW50ZXh0")
print(result.ciphertext)

result = client.decrypt("Y2hhbGxlbmdl", ehsm_key.keyid, result.ciphertext)
print(result.plaintext)