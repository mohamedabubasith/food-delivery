from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.main import app
from backend.common.database import Base, get_db
from backend.common import models
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
client = TestClient(app)

@pytest.fixture(scope="function", autouse=True)
def setup_db():
    # Force drop persistent old table that might not be in metadata anymore
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
    
    user = models.User(name=name, phone_number=phone, role=role, city="Test City")
    db.add(user)
    db.commit()
    db.refresh(user)
    
    from backend.common.utils import security
    token = security.create_access_token(data={"sub": str(user.id), "role": role})
    db.close()
    return {"Authorization": f"Bearer {token}"}, user.id

def test_banners_flow():
    admin_headers, _ = get_auth_headers(role=1)
    user_headers, _ = get_auth_headers(role=0)

    # 1. Admin Creates Banner
    banner_data = {
        "image_url": "http://img.com/banner1.png",
        "title": "50% Off",
        "deep_link": "app://promo/50off",
        "priority": 10
    }
    res = client.post("/restaurants/marketing/banners", json=banner_data, headers=admin_headers)
    assert res.status_code == 200
    assert res.json()["data"]["title"] == "50% Off"

    # 2. Public Fetches Banners
    res = client.get("/restaurants/marketing/banners", headers=user_headers)
    assert res.status_code == 200
    assert len(res.json()["data"]) == 1
    assert res.json()["data"][0]["priority"] == 10

def test_collections_flow():
    admin_headers, _ = get_auth_headers(role=1)
    user_headers, _ = get_auth_headers(role=0)

    # Setup: Create Food first
    import json
    food_data = {"food_name": "Special Pizza", "food_category": "Pizza", "food_price": 99, "food_quantity": 10}
    res = client.post("/menu/", data={"food_data": json.dumps(food_data)}, headers=admin_headers)
    assert res.status_code == 200
    food_id = res.json()["data"]["food_id"]

    # 1. Admin Creates Collection
    coll_data = {
        "title": "Weekend Specials",
        "image_url": "http://img.com/coll.png",
        "description": "Tasty Pizzas",
        "food_ids": [food_id]
    }
    res = client.post("/restaurants/marketing/collections", json=coll_data, headers=admin_headers)
    assert res.status_code == 200
    assert res.json()["data"]["title"] == "Weekend Specials"

    # 2. Public View Collections
    res = client.get("/restaurants/marketing/collections", headers=user_headers)
    assert res.status_code == 200
    data = res.json()["data"]
    assert len(data) == 1
    assert data[0]["title"] == "Weekend Specials"
    # Basic check if foods are linked
    assert len(data[0]["foods"]) == 1
    assert data[0]["foods"][0]["food_name"] == "Special Pizza"
