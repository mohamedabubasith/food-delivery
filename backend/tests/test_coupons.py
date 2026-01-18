from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.main import app
from backend.common.database import Base, get_db
from backend.common import models
import pytest
import os
from datetime import datetime, timedelta

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
client = TestClient(app)

@pytest.fixture(scope="function", autouse=True)
def setup_db():
    with engine.connect() as con:
        try:
            con.execute("DROP TABLE IF EXISTS collection_restaurants CASCADE")
        except:
            pass
            
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    
    # Seed Default Restaurant (ID 1)
    db = TestingSessionLocal()
    from backend.common.utils.seed_restaurant import seed_default_restaurant
    seed_default_restaurant(db)
    db.close()
    
    yield

def get_auth_headers(role=0):
    db = TestingSessionLocal()
    phone = "9999999999" if role == 1 else "8888888888"
    name = "Admin" if role == 1 else "User"
    user_id = 1 if role == 1 else 2
    
    user = models.User(id=user_id, name=name, phone_number=phone, role=role, city="Test City")
    db.merge(user) # Merge to avoid PK conflict if setup re-runs?
    db.commit()
    
    from backend.common.utils import security
    token = security.create_access_token(data={"sub": str(user_id), "role": role})
    db.close()
    return {"Authorization": f"Bearer {token}"}

def test_coupon_crud_and_apply():
    admin_headers = get_auth_headers(role=1)
    user_headers = get_auth_headers(role=0)

    # 1. Admin Create Coupon
    valid_until = (datetime.now() + timedelta(days=5)).isoformat()
    coupon_data = {
        "code": "TEST50",
        "discount_type": "percentage",
        "discount_value": 50.0,
        "min_order_value": 100.0,
        "max_discount_amount": 50.0,
        "valid_until": valid_until
    }
    res = client.post("/restaurants/marketing/coupons", json=coupon_data, headers=admin_headers)
    assert res.status_code == 200
    assert res.json()["data"]["code"] == "TEST50"

    # 2. Public Get Coupons
    res = client.get("/restaurants/marketing/coupons", headers=user_headers)
    assert res.status_code == 200
    assert len(res.json()["data"]) >= 1

    # 3. Apply Logic (Valid)
    res = client.post("/restaurants/marketing/apply-coupon", json={"code": "TEST50", "cart_total": 200.0})
    assert res.status_code == 200
    data = res.json()["data"]
    assert data["valid"] == True
    assert data["discount_amount"] == 50.0 # 50% of 200 is 100, but capped at 50

    # 4. Apply Logic (Invalid - Min Order)
    res = client.post("/restaurants/marketing/apply-coupon", json={"code": "TEST50", "cart_total": 50.0})
    assert res.status_code == 400
    assert "Minimum order value" in res.json()["message"]

def test_checkout_with_coupon():
    """
    Verify that checkout endpoint accepts a valid coupon and applies discount correctly.
    """
    admin_headers = get_auth_headers(role=1)
    user_headers = get_auth_headers(role=0)

    # 1. Create Food (Price: 200)
    import json
    food_data = {"food_name": "Pricey Burger", "food_category": "American", "food_price": 200, "food_quantity": 100}
    res = client.post("/menu/", data={"food_data": json.dumps(food_data)}, headers=admin_headers)
    assert res.status_code == 200
    food_id = res.json()["data"]["food_id"]

    # 2. Create Coupon (FLAT ₹50 OFF)
    valid_until = (datetime.now() + timedelta(days=5)).isoformat()
    coupon_data = {
        "code": "FLAT50",
        "discount_type": "flat",
        "discount_value": 50.0,
        "min_order_value": 100.0,
        "valid_until": valid_until
    }
    client.post("/restaurants/marketing/coupons", json=coupon_data, headers=admin_headers)

    # 3. Checkout with Coupon
    checkout_payload = {
        "items": [{"food_id": food_id, "quantity": 1}],
        "coupon_code": "FLAT50"
    }
    res = client.post("/orders/checkout", json=checkout_payload, headers=user_headers)
    assert res.status_code == 200
    data = res.json()["data"]
    
    # Verify Math
    assert data["total_amount"] == 200.0
    assert data["discount_amount"] == 50.0
    assert data["final_amount"] == 150.0
    assert data["status"] == "success"

    # 4. Checkout with Invalid Coupon (Min Order Fail)
    # Pricey Burger costs 200. Let's make a new food for 50.
    food_data2 = {"food_name": "Cheap Fries", "food_category": "Sides", "food_price": 50, "food_quantity": 100}
    res = client.post("/menu/", data={"food_data": json.dumps(food_data2)}, headers=admin_headers)
    food_id2 = res.json()["data"]["food_id"]
    
    checkout_payload_fail = {
        "items": [{"food_id": food_id2, "quantity": 1}],
        "coupon_code": "FLAT50" # Needs 100
    }
    res = client.post("/orders/checkout", json=checkout_payload_fail, headers=user_headers)
    assert res.status_code == 400 # Should fail now as per updated service logic
    assert "Minimum order value" in res.json()["message"]
