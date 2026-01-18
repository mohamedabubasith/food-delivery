from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.main import app
from backend.common.database import Base, get_db
from backend.common_auth.service import AuthService
from backend.common import models
from backend.common.utils import sms
import pytest
import os

TEST_DATABASE_URL = os.getenv("TEST_DATABASE_URL", "postgresql://admin:admin@localhost/local_eats_test_db")

engine = create_engine(TEST_DATABASE_URL)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

# Mock SMS
sms.send_sms_verify = lambda to, code: True

client = TestClient(app)

@pytest.fixture(scope="function", autouse=True)
def setup_db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    
    # Seed Default Restaurant for Multi-Tenancy Tests
    db = TestingSessionLocal()
    from backend.common.utils.seed_restaurant import seed_default_restaurant
    seed_default_restaurant(db)
    db.close()
    
    yield

def test_register_success():
    response = client.post("/auth/register", json={
        "name": "Test User",
        "phone_number": "9876543210",
        "city": "Test City"
    })
    assert response.status_code == 200
    data = response.json()
    assert data["phone_number"] == "9876543210"

def test_login_flow():
    phone = "9876543210"
    client.post("/auth/register", json={"name": "Login User", "phone_number": phone, "city": "Login City"})
    
    # Explicitly set provider to local since we changed default to firebase
    res = client.post("/auth/login", json={"phone_number": phone, "provider": "local"})
    assert res.status_code == 200
    
    db = TestingSessionLocal()
    auth_entry = db.query(models.Auth).filter(models.Auth.phone_number == phone).first()
    code = auth_entry.verify_code
    db.close()
    
    res = client.post("/auth/token", json={"phone_number": phone, "verify_code": code})
    assert res.status_code == 200
    assert "access_token" in res.json()

def test_full_system_integration():
    # Setup Admin
    db = TestingSessionLocal()
    admin = models.User(name="Admin", phone_number="9999999999", role=1, city="Admin City")
    db.add(admin)
    db.commit()
    from backend.common.utils import security
    admin_token = security.create_access_token(data={"sub": str(admin.id)}) # Use ID
    admin_header = {"Authorization": f"Bearer {admin_token}"}
    
    # Setup User
    user = models.User(name="User", phone_number="8888888888", role=0, city="User City")
    db.add(user)
    db.commit()
    user_id = user.id
    user_token = security.create_access_token(data={"sub": str(user.id)}) # Use ID
    user_header = {"Authorization": f"Bearer {user_token}"}
    db.close()
    
    # 1. Core Restaurant: Create Menu
    import json
    food_data = {"food_name": "Modular Pizza", "food_category": "Test", "food_price": 25.0, "food_quantity": 10}
    res = client.post("/menu/", data={"food_data": json.dumps(food_data)}, headers=admin_header)
    assert res.status_code == 200
    food_id = res.json()["food_id"]
    
    # 2. Core Restaurant: Create Order
    res = client.post("/orders/", json={"food_id": food_id, "quantity": 1}, headers=user_header)
    assert res.status_code == 200
    order_id = res.json()["id"]
    
    # 3. Kitchen Service: Update Status
    res = client.put(f"/kitchen/orders/{order_id}/status", json={"status": "finished"}, headers=admin_header)
    assert res.status_code == 200
    assert res.json()["status"] == "finished"

    # 4. Table Management
    res = client.post("/tables/", json={"name": 1, "seat": 4}, headers=admin_header)
    assert res.status_code == 200
    table_id = res.json()["id"]

    # 5. Reservation Flow
    # Check availability
    res = client.post("/reservations/check", params={"slot": 1, "r_date": "2023-01-01", "person": 2}, headers=user_header)
    # The check API in controller uses body/params mixed up in original design, let's fix the test to match strict API logic
    # My controller defined check_table args as query parameters because `check_available` schema was in body but `person` was separate.
    # Actually, let's look at my controller definition:
    # def check_availability(slot: int, r_date: date, person: int, ...)
    # These are Query params by default in FastAPI if not Pydantic model.
    res = client.post(f"/reservations/check?slot=1&r_date=2023-01-01&person=2", headers=user_header) 
    assert res.status_code == 200
    
    # Create Reservation
    res = client.post("/reservations/", json={"table_id": table_id, "slot": 1, "r_date": "2023-01-01"}, headers=user_header)
    assert res.status_code == 200
    
    # 6. Billing
    res = client.get(f"/bill/{user_id}", headers=user_header)
    assert res.status_code == 200
    assert "total_amount" in res.json()

    # 7. Auth Panel
    res = client.get("/auth/panel", headers=user_header)
    assert res.status_code == 200
    assert res.json()["name"] == "User"

    # 8. Food Variants & Images
    # Upload Image (Mock)
    # Testing file upload is tricky with TestClient, simplified here
    
    # Create Food with Variants
    variant_food_data = {
        "food_name": "Chicken BBQ",
        "food_category": "Grill",
        "food_price": 0, # Base price 0, variants have price
        "food_quantity": 100,
        "image_url": "http://mock-cloud/image.jpg",
        "variants": [
            {"variant_name": "Quarter", "variant_price": 150},
            {"variant_name": "Half", "variant_price": 280},
            {"variant_name": "Full", "variant_price": 550}
        ]
    }
    # Using data= for multipart/form-data
    res = client.post("/menu/", data={"food_data": json.dumps(variant_food_data)}, headers=admin_header)
    assert res.status_code == 200
    bbq_id = res.json()["food_id"]
    variants = res.json()["variants"]
    assert len(variants) == 3
    half_variant_id = next(v["id"] for v in variants if v["variant_name"] == "Half")
    
    # Order a Variant
    res = client.post("/orders/", json={"food_id": bbq_id, "variant_id": half_variant_id, "quantity": 1}, headers=user_header)
    assert res.status_code == 200
    assert res.json()["variant"]["variant_name"] == "Half"

    # 9. Zomato Features: Description, Veg, Search, Favorites
    # Create Veg Item
    veg_food = {
        "food_name": "Paneer Tikka",
        "food_category": "Starters",
        "food_price": 200,
        "food_quantity": 50,
        "description": "Delicious spicy paneer chunks",
        "is_veg": True
    }
    res = client.post("/menu/", data={"food_data": json.dumps(veg_food)}, headers=admin_header)
    assert res.status_code == 200
    paneer_id = res.json()["food_id"]
    
    # Toggle Favorite
    res = client.post(f"/menu/{paneer_id}/favorite", headers=user_header)
    assert res.status_code == 200
    assert res.json()["status"] == "added"
    
    # Get Favorites
    res = client.get("/menu/favorites", headers=user_header)
    assert res.status_code == 200
    assert len(res.json()) > 0
    assert res.json()[0]["food_name"] == "Paneer Tikka"
    
    # Search
    res = client.get("/menu/?search=paneer", headers=user_header)
    assert len(res.json()) == 1
    assert res.json()[0]["food_name"] == "Paneer Tikka"
    
    # Filter by Veg
    res = client.get("/menu/?is_veg=true", headers=user_header)
    # Should find Paneer Tikka (Veg) but NOT Chicken BBQ (Non-Veg default)
    # Check that *all* returned are veg
    for item in res.json():
        assert item["is_veg"] is True
    
    # Filter by Price Range
    res = client.get("/menu/?min_price=100&max_price=300", headers=user_header)
    # Quarter BBQ (150) - variants not main price?, Paneer (200), BBQ (0 base?)
    # Note: Our search filters on *base* price currently.
    # Paneer is 200.
    found_paneer = False
    for item in res.json():
        if item["food_name"] == "Paneer Tikka":
            found_paneer = True
    assert found_paneer is True

    # 10. Address & Batch Checkout Flow
    # Create Address
    address_data = {
        "label": "Home",
        "address_line": "123 Main St",
        "city": "Metropolis",
        "zip_code": "560001"
    }
    res = client.post("/auth/addresses", json=address_data, headers=user_header)
    assert res.status_code == 200
    address_id = res.json()["id"]
    
    # Checkout (Batch Order)
    checkout_data = {
        "items": [
            {"food_id": bbq_id, "variant_id": half_variant_id, "quantity": 2}, # 2 * 280 = 560
            {"food_id": paneer_id, "quantity": 1} # 200
        ], # Total = 760
        "address_id": address_id,
        "coupon_code": "DIWALI10" # 10% off = 76
    }
    # Final should be 760 - 76 = 684
    
    res = client.post("/orders/checkout", json=checkout_data, headers=user_header)
    assert res.status_code == 200
    summary = res.json()
    assert summary["total_amount"] == 760.0
    assert summary["discount_amount"] == 76.0
    assert summary["final_amount"] == 684.0
    assert "batch_id" in summary

    assert "batch_id" in summary

    assert "batch_id" in summary

    # 11. External Provider Auth (Firebase - Mocked)
    # Token format: mock_firebase_token_{phone_number}
    fb_token = "mock_firebase_token_+918888888888" 
    login_payload = {
        "token": fb_token,
        "provider": "firebase"
    }
    # Use standard /auth/login
    res = client.post("/auth/login", json=login_payload)
    assert res.status_code == 200
    assert "access_token" in res.json()
    
    # Verify user was created
    fb_header = {"Authorization": f"Bearer {res.json()['access_token']}"}
    res = client.get("/auth/me", headers=fb_header)
    assert res.status_code == 200
    assert res.json()["phone_number"] == "+918888888888"
