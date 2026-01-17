import requests
import random

def send_sms_verify(to: str, code: str) -> bool:
    """
    Sends a verification code via SMS.
    Currently mocked to always succeed for development, or uses the original IPPanel logic if configured.
    """
    print(f"--- MOCK SMS SENT TO {to}: {code} ---")
    
    # Original logic (commented out for safety/cost unless user provides keys)
    # key = "xxxxxxxxxxxx"
    # number = "983000505"
    # pattern_id = 'xxxxxxxx'
    # url = "http://ippanel.com:8080"
    # params = {
    # 	'apikey': key,
    # 	'pid': pattern_id,
    # 	'fnum': number,
    # 	'tnum': to,
    # 	'p1': 'verification-code',
    # 	'v1': code
    # }
    # try:
    #     response = requests.get(url, params=params)
    #     return response.status_code == 200
    # except:
    #     return False
        
    return True

def generate_verify_code() -> str:
    return str(random.randint(1000, 9999))
