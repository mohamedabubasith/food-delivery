from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.main import app
from backend.common.database import Base, get_db
from backend.common import models
import pytest
import os
import io

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
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    
    db = TestingSessionLocal()
    from backend.common.utils.seed_restaurant import seed_default_restaurant
    seed_default_restaurant(db)
    db.close()
    
    yield

def get_auth_headers(role=0):
    db = TestingSessionLocal()
    phone = "999" if role == 1 else "111"
    name = "Admin" if role == 1 else "User"
    
    user = models.User(name=name, phone_number=phone, role=role, city="Test City")
    db.add(user)
    db.commit()
    db.refresh(user)
    
    from backend.common.utils import security
    token = security.create_access_token(data={"sub": str(user.id), "role": role})
    db.close()
    return {"Authorization": f"Bearer {token}"}, user.id

def test_auth_misc_endpoints():
    headers, _ = get_auth_headers(role=0)
    
    # 1. GET /auth/hi
    res = client.get("/auth/hi")
    assert res.status_code == 200
    assert res.json()["message"] == "Hi"
    
    # 2. GET /auth/whoiam
    res = client.get("/auth/whoiam", headers=headers)
    assert res.status_code == 200
    assert res.json()["admin"] is False
    
    # 3. GET /auth/addresses
    # First create one
    client.post("/auth/addresses", json={"label": "Work", "address_line": "123", "city": "City", "zip_code": "000"}, headers=headers)
    # Then List
    res = client.get("/auth/addresses", headers=headers)
    assert res.status_code == 200
    assert len(res.json()) == 1
    assert res.json()[0]["label"] == "Work"

from unittest.mock import patch

# ... existing code ...

def test_core_misc_endpoints():
    admin_headers, _ = get_auth_headers(role=1) # Admin needed for upload
    user_headers, user_id = get_auth_headers(role=0)
    
    # 1. POST /menu/upload-image
    # Simulate file upload
    file_content = b"fake image content"
    files = {"file": ("test.jpg", file_content, "image/jpeg")}
    
    # Mock MinioService to avoid real connection checks
    with patch("backend.common.utils.minio_service.MinioService.upload_file", return_value="http://mock-minio/test.jpg"):
        res = client.post("/menu/upload-image", files=files, headers=admin_headers)
        assert res.status_code == 200
        assert res.json()["image_url"] == "http://mock-minio/test.jpg" 
    
    # 2. Tables & Reservations List
    client.post("/tables/", json={"name": 99, "seat": 2}, headers=admin_headers)
    
    # GET /tables/
    res = client.get("/tables/", headers=user_headers)
    assert res.status_code == 200
    assert len(res.json()) == 1
    table_id = res.json()[0]["id"]
    
    # Create Reservation
    res = client.post("/reservations/", json={"table_id": table_id, "slot": 1, "r_date": "2025-01-01"}, headers=user_headers)
    r_id = res.json()["id"]
    
    # GET /reservations/
    res = client.get("/reservations/", headers=user_headers) # Endpoint uses TableService.get_reservations()
    assert res.status_code == 200
    assert len(res.json()) >= 1
    
    # DELETE /reservations/{id}
    res = client.delete(f"/reservations/{r_id}", headers=user_headers)
    assert res.status_code == 200
    
    # Verify deletion
    res = client.get("/reservations/", headers=user_headers)
    # Depending on implementation, might return empty list
    ids = [r["id"] for r in res.json()]
    assert r_id not in ids

    # 3. GET /orders/{id}
    # Create food & order first
    res = client.post("/menu/", json={"food_name": "Test", "food_category": "Test", "food_price": 10, "food_quantity": 10}, headers=admin_headers)
    food_id = res.json()["food_id"]
    res = client.post("/orders/", json={"food_id": food_id, "quantity": 1}, headers=user_headers)
    order_id = res.json()["id"]
    
    # Get Order Detail
    res = client.get(f"/orders/{order_id}", headers=user_headers)
    assert res.status_code == 200
    assert res.json()["id"] == order_id
    
    # Test Unauthorized Access (Another user)
    # Setup Another User
    db = TestingSessionLocal()
    other = models.User(name="Other", phone_number="222", role=0)
    db.add(other)
    db.commit()
    from backend.common.utils import security
    other_token = security.create_access_token(data={"sub": str(other.id)})
    other_headers = {"Authorization": f"Bearer {other_token}"}
    db.close()
    
    res = client.get(f"/orders/{order_id}", headers=other_headers)
    assert res.status_code == 403

def test_kitchen_endpoints():
    admin_headers, _ = get_auth_headers(role=1)
    user_headers, _ = get_auth_headers(role=0)
    
    # Setup Data
    res = client.post("/menu/", json={"food_name": "K-Test", "food_category": "Test", "food_price": 10, "food_quantity": 10}, headers=admin_headers)
    if res.status_code != 200:
        print(f"MENU CREATE FAILED: {res.json()}")
    assert res.status_code == 200
    
    food_id = res.json()["food_id"]
    client.post("/orders/", json={"food_id": food_id, "quantity": 1}, headers=user_headers)
    
    # GET /kitchen/orders (Default status=created)
    res = client.get("/kitchen/orders", headers=admin_headers)
    assert res.status_code == 200
    assert len(res.json()) >= 1
    assert res.json()[0]["status"] == "created"
    
    # Filter by non-existent status
    res = client.get("/kitchen/orders?status=finished", headers=admin_headers)
    assert res.status_code == 200
    assert len(res.json()) == 0

def test_marketplace_and_profile():
    admin_headers, _ = get_auth_headers(role=1)
    user_headers, user_id = get_auth_headers(role=0)

    # 1. Restaurant Management
    # Create (Admin)
    res = client.post("/restaurants/", json={
        "name": "New Tasty Spot",
        "address": "123 Flavor Town",
        "image_url": "http://img.com/logo.png"
    }, headers=admin_headers)
    assert res.status_code == 200
    r_id = res.json()["id"]

    # List (Public/User)
    res = client.get("/restaurants/?search=Tasty", headers=user_headers)
    assert res.status_code == 200
    assert len(res.json()) >= 1
    assert res.json()[0]["name"] == "New Tasty Spot"

    # Get Details
    res = client.get(f"/restaurants/{r_id}", headers=user_headers)
    assert res.status_code == 200
    assert res.json()["address"] == "123 Flavor Town"

    # 2. User Profile Update
    # Update Name & City
    update_data = {"name": "Updated Name", "city": "New City", "phone_number": "111"}
    res = client.put("/auth/me", json=update_data, headers=user_headers)
    assert res.status_code == 200
    assert res.json()["name"] == "Updated Name"
    assert res.json()["city"] == "New City"

    # Verify persistence
    res = client.get("/auth/me", headers=user_headers)
    assert res.json()["name"] == "Updated Name"

    # 3. Address Deletion
    # Create Address
    res = client.post("/auth/addresses", json={"label": "To Delete", "address_line": "X", "city": "X", "zip_code": "X"}, headers=user_headers)
    addr_id = res.json()["id"]

    # Delete
    res = client.delete(f"/auth/addresses/{addr_id}", headers=user_headers)
    assert res.status_code == 200
    
    res = client.get("/auth/addresses", headers=user_headers)
    ids = [a["id"] for a in res.json()]
    assert addr_id not in ids

def test_food_with_images():
    admin_headers, _ = get_auth_headers(role=1)
    
    # Prepare Multipart Request
    import json
    food_data = {
        "food_name": "Multi Image Burger",
        "food_category": "Fast Food",
        "food_price": 50,
        "food_quantity": 100,
        "description": "Tasty",
        "variants": [{"variant_name": "Mega", "variant_price": 80}]
    }
    
    files = [
        ("images", ("img1.jpg", b"fake1", "image/jpeg")),
        ("images", ("img2.jpg", b"fake2", "image/jpeg"))
    ]
    
    # Mock Storage
    with patch("backend.common.utils.minio_service.MinioService.upload_file", side_effect=["http://minio/1.jpg", "http://minio/2.jpg"]):
        res = client.post(
            "/menu/with-images", 
            data={"food_data": json.dumps(food_data)}, 
            files=files, 
            headers=admin_headers
        )
        assert res.status_code == 200
        data = res.json()
        assert data["food_name"] == "Multi Image Burger"
        assert len(data["images"]) == 2
        assert data["image_url"] == "http://minio/1.jpg" # Primary set to first
        assert data["images"][1]["image_url"] == "http://minio/2.jpg"
