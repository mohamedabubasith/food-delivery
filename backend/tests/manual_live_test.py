import requests
import time
import sys

BASE_URL = "http://127.0.0.1:8001" # Using 8001 to avoid conflicts

def run_live_test():
    print(f"Waiting for server at {BASE_URL}...")
    for i in range(10):
        try:
            requests.get(BASE_URL)
            print("Server is UP!")
            break
        except:
            time.sleep(1)
            print(".", end="", flush=True)
    else:
        print("\nServer failed to start.")
        sys.exit(1)

    print("\n--- 1. Register User ---")
    customer_phone = "11122233344"
    res = requests.post(f"{BASE_URL}/auth/register", json={
        "name": "Live Tester",
        "phone_number": customer_phone,
        "city": "Cyber City"
    })
    print(f"Register: {res.status_code} {res.text}")
    
    # Check if already exists (in case of re-run)
    if res.status_code == 400:
        print("User might already exist, proceeding to login...")

    print("\n--- 2. Login & Get Token ---")
    requests.post(f"{BASE_URL}/auth/login", json={"phone_number": customer_phone})
    
    # We need to hack the OTP since we can't see the mock console output easily in this mode
    # However, our utils/sms.py mocks sending, but we need to know what code was generated.
    # IN CRUD, we store it. We can't access DB directly here easily without imports.
    # Wait! I can modify the app to print it or have a fixed code for specific number for testing?
    # Or I can just import the DB logic here purely to get the code.
    
    from unified_backend import database, models
    db = next(database.get_db())
    auth_entry = db.query(models.Auth).filter(models.Auth.phone_number == customer_phone).first()
    otp_code = auth_entry.verify_code
    print(f"Recovered OTP from DB: {otp_code}")
    
    res = requests.post(f"{BASE_URL}/auth/token", json={
        "phone_number": customer_phone, 
        "verify_code": otp_code
    })
    if res.status_code != 200:
        print(f"Failed to get token: {res.text}")
        sys.exit(1)
        
    token = res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    print(f"Got Token: {token[:10]}...")

    print("\n--- 3. Create Order ---")
    # Need a food item first. We need a kitchen user for that. 
    # Let's cheat and use the same user promoted to kitchen for this test, or just use SQL to insert food.
    # Let's insert food directly via DB to simplify "Live Test" without needing dual logins.
    food = models.Food(food_name="Live Pizza", food_category="Fast Food", food_price=15.00, food_quantity=10)
    try:    
        db.add(food)
        db.commit()
    except:
        db.rollback() 
        # Food might exist
        food = db.query(models.Food).filter(models.Food.food_name == "Live Pizza").first()
    
    print(f"Using Food ID: {food.food_id}")
    
    res = requests.post(f"{BASE_URL}/orders/", json={
        "food_id": food.food_id,
        "quantity": 1
    }, headers=headers)
    print(f"Order Created: {res.status_code} {res.json()}")
    order_id = res.json()["id"]

    print("\n--- 4. Check Order Status ---")
    res = requests.get(f"{BASE_URL}/orders/{order_id}", headers=headers)
    print(f"Order Status: {res.json()['status']}")

    print("\n--- LIVE TEST COMPLETED SUCCESSFULLY ---")

if __name__ == "__main__":
    run_live_test()
