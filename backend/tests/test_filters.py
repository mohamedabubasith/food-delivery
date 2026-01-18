from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.main import app
from backend.common.database import Base, get_db
from backend.common import models
import pytest
import os
import json

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
    
    # Seed Data
    db = TestingSessionLocal()
    # 1. Restaurant
    r = models.Restaurant(id=1, name="Test Rest", address="Loc", is_active=True, latitude=0.0, longitude=0.0)
    db.add(r)
    
    # 2. Foods
    # Pizza: 100, Veg, Rating 4.0
    db.add(models.Food(restaurant_id=1, food_name="Pizza", food_category="Italian", food_price=100.0, food_quantity=10, is_veg=True, rating=4.0))
    # Burger: 200, Non-Veg, Rating 5.0
    db.add(models.Food(restaurant_id=1, food_name="Burger", food_category="American", food_price=200.0, food_quantity=10, is_veg=False, rating=5.0))
    # Pasta: 150, Veg, Rating 3.5
    db.add(models.Food(restaurant_id=1, food_name="Pasta", food_category="Italian", food_price=150.0, food_quantity=10, is_veg=True, rating=3.5))
    
    db.commit()
    db.close()
    
    yield

def test_menu_meta():
    res = client.get("/menu/filters")
    assert res.status_code == 200
    data = res.json()["data"]
    assert data["min_price"] == 100.0
    assert data["max_price"] == 200.0
    assert "Italian" in data["categories"]
    assert "American" in data["categories"]

def test_menu_filtering():
    # 1. Filter by Category
    res = client.get("/menu/?category=Italian")
    data = res.json()["data"]
    assert len(data) == 2
    assert all(f["food_category"] == "Italian" for f in data)

    # 2. Filter by Veg
    res = client.get("/menu/?is_veg=true")
    data = res.json()["data"]
    assert len(data) == 2
    assert all(f["is_veg"] == True for f in data)

    # 3. Filter by Price Range
    res = client.get("/menu/?min_price=120&max_price=180")
    data = res.json()["data"]
    assert len(data) == 1
    assert data[0]["food_name"] == "Pasta"

def test_menu_sorting():
    # 1. Sort by Price High -> Low
    res = client.get("/menu/?sort_by=price_high")
    data = res.json()["data"]
    assert data[0]["food_name"] == "Burger" # 200
    assert data[2]["food_name"] == "Pizza"  # 100

    # 2. Sort by Rating
    res = client.get("/menu/?sort_by=rating")
    data = res.json()["data"]
    assert data[0]["food_name"] == "Burger" # 5.0
    assert data[2]["food_name"] == "Pasta"  # 3.5
