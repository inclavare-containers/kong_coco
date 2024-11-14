import requests  
import urllib.parse  
import base64  
import hmac  
import hashlib  
from hashlib import sha256  
import json  
import time  
from collections import OrderedDict  
from typing import Dict, Optional, Union  
from typing_extensions import Buffer
import copy  
import warnings  
from requests.packages.urllib3.exceptions import InsecureRequestWarning  
warnings.simplefilter('ignore', InsecureRequestWarning)  

def params_sort_str(params: Dict) -> str:
    items = filter(lambda it: it[1] is not None, params.items())
    return urllib.parse.unquote_plus(
        urllib.parse.urlencode(OrderedDict(sorted(items, key=lambda k: k[0])))
    )


def prepare_params(payload: Optional[Dict], appid: str, apikey: str):
    """
    Add timestamp, appid and signature to request params.

    Signature is the HMAC(SHA256) of a combination of `appid`, `timestamp` (and
    `payload` if payload is specified).
    """
    # make a copy so that the input will not be affected
    payload = copy.deepcopy(payload)
    timestamp = str(int(time.time() * 1000))
    # add timestamp and appid to params
    params = OrderedDict()
    params["appid"] = appid
    params["timestamp"] = timestamp
    if payload is not None:
        # `payload` field here is for signing, the real payload is still an object
        # instead of a string
        params["payload"] = params_sort_str(payload)
    # convert params to a string using urllib
    params_str = params_sort_str(params)
    signature = str(
        base64.b64encode(
            hmac.new(
                apikey.encode("utf-8"),
                params_str.encode("utf-8"),
                digestmod=hashlib.sha256,
            ).digest()
        ),
        "utf-8",
    )
    # append to params
    params["sign"] = signature
    if payload is not None:
        params["payload"] = payload
    return params

payload = OrderedDict()
my_aad = "This is wydx"  
encoded_aad = base64.b64encode(my_aad.encode()).decode()  
#payload["aad"] = encoded_aad
payload["aad"] = "Y2hhbGxlbmdl"
payload["keyid"] = "c0cb2847-9fa9-4d0e-80e5-3ea65b952bb5"
payload["ciphertext"] = "284"

params = prepare_params(payload, "5c6af423-0cf0-4f0e-82d2-1f175bec91cb", "Fkb9N5zTgnJyzRiejKgKcsaAcyPGLCiZ") 

headers = {'Content-Type': 'application/json'} 
response = requests.post(url="https://8.212.3.169:9000/ehsm?Action=Decrypt", data=json.dumps(params), headers=headers, verify=False, stream=True)

# 打印状态码  
print("Response Status Code:", response.status_code)  
  
# 打印头部信息  
print("Headers:")  
for key, value in response.headers.items():  
    print(f"{key}: {value}")  
  
# 打印正文内容（如果存在）    
if 'content-type' in response.headers and 'text' in response.headers['content-type']:    
    print("Response Body:")    
    print(response.text)    
else:    
    print("Response Body:")    
    # 将二进制数据解码为Python字典  
    body_dict = json.loads(response.content)  
    print(body_dict)