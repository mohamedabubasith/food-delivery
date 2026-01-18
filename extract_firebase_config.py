import base64
import json
import os
import requests
from google.oauth2 import service_account
import google.auth.transport.requests

def get_firebase_web_config():
    # 1. Get Service Account from .env
    # (In this environment I can probably just hardcode the vars I saw or read .env again)
    # But I'll just use the one I grep-ed.
    
    b64_cred = """ewogICJ0eXBlIjogInNlcnZpY2VfYWNjb3VudCIsCiAgInByb2plY3RfaWQiOiAibXktcHJvamVjdC0xNjMwNTA0NDgxNDIxIiwKICAicHJpdmF0ZV9rZXlfaWQiOiAiNzdhYTVhYmQyYTc2MjMxMzhiOWI4Mzc3OTkxZmZkY2Y2NmY2OTE3YyIsCiAgInByaXZhdGVfa2V5IjogIi0tLS0tQkVHSU4gUFJJVkFURSBLRVktLS0tLVxuTUlJRXZBSUJBREFOQmdrcWhraUc5dzBCQVFFRkFBU0NCS1l3Z2dTaUFnRUFBb0lCQVFERFFNZVZZYjV5SFMrcFxub0lnVkpIaHlMRzF2Q1FIWVlYNkxJeUNRRkJsd1JUMkYzREVrby9XeUhnYU9iaDNYNW1EeHVvb0ErNC9ocS92RFxudE9acFltN0lId0ZjVEptMWZuNHVoRXVGaUdXcU14WFY5cnA3NGoyTE9ONU5nc3JhYkJqNXJWenY1SVZueDRLQlxuSGxaWXJiSVpyMFBiNVJ6MWNDRGdnRmlBaXdqdU40WitkNTFmZHVmRS9URnBDMzVHbitucFBpb0FvaWVIU01wN1xuOXhWQ1RxdWg4SENrY1FvUGRnWE44eFVTVVZKZTcycFZueFBZWlBKZFZzVDduMGcvNFl6czI2Nko4R0ZXMHpXalxuRktlNWF1TkJ0em5pelptemR4MVhleW9yNzZaMTBlOTRyZFppVDlYcUVKcFVTVG5GNjFYTHZTR2RxdEtRSEo4aVxuOExocnBKbERBZ01CQUFFQ2dnRUFWdFVrelZ6Q1B1cVc2MGVPcldSaVFsaGF0S0liVlhrS04yT0FWRUwwQ3pkblxueEhPbjBVVXZlNjZadU5iazQ4SzdRMVZ6a1R0UEFnd2pzNlhzUUZxN3JMa0pPRnlDa1RIM2VNVng5cWt4bVU4TlxudTNGMS9xa2ZPSjZxVW10RHZuNkxYdUpIN2hIQmVHVkVOeHJnU0tDNmoyeWY3NWZFV091c1cxc0l3T1hVSzJmelxudm5MT0t3TWxSS2tZTWRuNFhiMURYR3JzbXUvM1dDL3hxZm0vMmVrYTNTUGpQdUpSUElMNlZ2M2NDVGkzNEpTRlxuNWVheGhvbmxBRmJLYUVEYTI2Tjl4Tnd4WW5uYnZaZjhBZHVwTG5IUWROaGhxeW5Ob0Rydm5BMzhSdmtGWUZKa1xuUGh6ejVXV2MzMTVxN1dmU1NMNmUyYkdWdHhKVTZxeGFkNTVOM3QrbExRS0JnUUR3ay9DY1hPZndKWkUzdWNsbVxuazlYNTFHVnl5REx3RzczcFpNWVhEdDZwVTVZSUt2UXNLUXo2YkxFNHhBMjMwMlA5QW1KMSt0QzV0UENDZzVwd1xuSHQvb1BYZmlLcXlMaFkxLytqcFExak9iS0d1QjBlVm1tWjJvRWlBOWRkWWNnYmlUTHZHaFpyV04yV29FQmhZSVxuMSs3VlNkRUFuK0JicWJWNGhNNGJtZStFSFFLQmdRRFB4UWFVUVF2SmtXMHIwU2IrVnFxSkxsSVU3Ym5CWFNjT1xuVHhCb1cydWxSTmFoUjVJSzlPTlk4b29PY3pvdXVHekYxQnAxVFJ6ZisxU3pBTHRvbjByeWE2a1VuN1VmaFRmZVxueTA4a2E4S1pEaHBFaHZyT0VYcHIvY0JJbFRodWpPR3dvL2R2SThxa0pJOTNZRGkzL0FLVEwvSkdGQkhpSWkrQlxuaTRERFlKTlUzd0tCZ0IzWUhHY3BWMVNCTkl5WExaYmVEQk5iOStIUFdCSlZQcS92WW11RjJyVml1eC8wUkNvZVxuUlkvalgvRE0wVzdXZUhid2pzcFgvUUNzbzVGdFJnRldzeXdhUS83NGtFTVdwRUVXQjVuem1KOU0ybGxXY29EUlxuMmE3NTRLbi9ManFIRlNDZEdEaVBoMEk3a0YxRGJBUlkxVFg4WEVNWmtqbU15Z2hUWVVZblNJRTVBb0dBUE5tZFxuZGFvZlE2ZWQ2NmxUM0VXUnFKK3lWb0xSVm5wcng5c01HU1E5UUtnS25DMlQ3aldPcUN4UWxxN1VxWDVHRFNKelxucFVzeVc3OEdMVzdYZEdyQ3pvRU5nZ2JNU3pEL0RmZEpkSWRDOVFTV1dOK1hjT2JaamV0QmQ0Q01pSVFtVFUrWVxuVmlxTFhNdUFZUndEUUk5RVNjdFBENHN0T2FkOWRsbGZHdG1jRE0wQ2dZQlBlQy9XSWVvNHJycUxXQWNPZTZGUFxuc3gvRDhrbG9YeVNzQm5TYzY5ZDdzaFIzcEhPUmhxK1k3cVZObGdsVnZtdmxDdG5WYUoyQnVLWTQvaFZETmVyRFxuRXcwYjYyYlBaUGRNWmlkSDRsOHk0ZWVtMWl1aTVhZ0ZIR1dZdkFXbnZ6RmpIbVFBbEVGTkNxVkdJNk1yZWhzNVxuSFBESzhBY3huU3BNSUdIU1JteUJQZz09XG4tLS0tLUVORCBQUklWQVRFIEtFWS0tLS0tXG4i"""
    
    cred_json = base64.b64decode(b64_cred).decode('utf-8')
    info = json.loads(cred_json)
    project_id = info['project_id']
    
    scopes = ['https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/firebase']
    credentials = service_account.Credentials.from_service_account_info(info, scopes=scopes)
    
    request = google.auth.transport.requests.Request()
    credentials.refresh(request)
    access_token = credentials.token
    
    print(f"Project ID: {project_id}")
    
    # 2. List Web Apps
    apps_url = f"https://firebase.googleapis.com/v1beta1/projects/{project_id}/webApps"
    headers = {"Authorization": f"Bearer {access_token}"}
    
    resp = requests.get(apps_url, headers=headers)
    if resp.status_code != 200:
        print(f"Error listing apps: {resp.text}")
        return
        
    apps = resp.json().get('apps', [])
    if not apps:
        print("No web apps found.")
        return
        
    for app in apps:
        app_id = app['appId']
        display_name = app.get('displayName', 'Unnamed')
        print(f"\nApp: {display_name} ({app_id})")
        
        # 3. Get Config
        config_url = f"https://firebase.googleapis.com/v1beta1/projects/{project_id}/webApps/{app_id}/config"
        config_resp = requests.get(config_url, headers=headers)
        if config_resp.status_code == 200:
            config = config_resp.json()
            print("Config:")
            print(json.dumps(config, indent=2))
        else:
            print(f"Error getting config for {app_id}: {config_resp.text}")

if __name__ == "__main__":
    get_firebase_web_config()
