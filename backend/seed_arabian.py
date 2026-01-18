import sys
import os
import random

from sqlalchemy.orm import Session
from sqlalchemy.sql import func, text

# Add parent directory to path to allow imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from common import database, models
from common.utils import security

def seed_arabian_data():
    print("Connecting to database...")
    db = next(database.get_db())

    # 1. Create or Get Arabian Restaurant
    restaurant_data = {
        "name": "Al-Brisk Arabian Mandi",
        "address": "123 Arabian Street, Food Court",
        "image_url": "https://images.unsplash.com/photo-1549488344-1f9b8d2bd1f3", # Mandi platter
        "latitude": 25.2048,
        "longitude": 55.2708
    }

    # Find by Name (Safer than ID)
    restaurant = db.query(models.Restaurant).filter(models.Restaurant.name == restaurant_data["name"]).first()
    
    if restaurant:
        print(f"🔄 Found existing restaurant: {restaurant.name} (ID: {restaurant.id})")
        restaurant.address = restaurant_data["address"]
        restaurant.image_url = restaurant_data["image_url"]
    else:
        print("🌱 Creating new restaurant...")
        restaurant = models.Restaurant(**restaurant_data)
        db.add(restaurant)
    
    db.commit()
    db.refresh(restaurant)
    
    # ...

    # 2. Add Arabian Food Items
    # Define items (Alfam update)
    menu_items = [
        # ... (Same list, I need to keep the list content or I will lose it if I assume I am just replacing a block)
        # Wait, if I replace lines 18-43 (Restaurant Logic) AND loop logic (116-132)
        # I need MultiReplace?
        # The prompt "ReplacementContent" must replace the Target.
    ]
    # I cannot replace disjoint blocks with one call easily unless huge block.
    # I'll enable AllowMultiple? No.
    # I'll do 2 edits.
    print(f"✅ Active Restaurant: {restaurant.name} (ID: {restaurant.id})")

    # Clear existing food for this restaurant to avoid duplicates
    # Clear existing variants and food for this restaurant
    # Delete variants first to avoid FK constraint
    # (Assuming we can join or just delete all variants for foods of this restaurant)
    foods_to_delete = db.query(models.Food).filter(models.Food.restaurant_id == restaurant.id).all()
    for f in foods_to_delete:
        db.query(models.FoodVariant).filter(models.FoodVariant.food_id == f.food_id).delete()
    db.commit()

    db.query(models.Food).filter(models.Food.restaurant_id == restaurant.id).delete()
    db.commit()

    # 2. Add Arabian Food Items
    foods = [
        models.Food(
            food_name="Special Chicken Mandi",
            food_category="Mandi",
            food_price=380.0,
            food_quantity=50,
            image_url="https://images.unsplash.com/photo-1633945274405-b6c809047b0?q=80&w=2940&auto=format&fit=crop",
            description="Traditional Yemeni mandi with tender chicken and aromatic rice.",
            is_veg=False,
            restaurant_id=restaurant.id,
            variants=[
                models.FoodVariant(variant_name="Quarter", variant_price=160.0),
                models.FoodVariant(variant_name="Half", variant_price=280.0),
                models.FoodVariant(variant_name="Full", variant_price=520.0),
            ]
        ),
        models.Food(
            food_name="Mutton Kabsa",
            food_category="Mandi", 
            food_price=450.0,
            food_quantity=30,
            image_url="https://images.unsplash.com/photo-1596797038530-2c107229654b?q=80&w=2835&auto=format&fit=crop",
            description="Spiced rice with slow-cooked mutton.",
            is_veg=False,
            restaurant_id=restaurant.id # Use dynamic restaurant.id
        ),
        models.Food(
            food_name="Chicken Shawarma Plate",
            food_category="Shawarma",
            food_price=180.0,
            food_quantity=100,
            image_url="https://images.unsplash.com/photo-1662116812822-29c3629e471d?q=80&w=2540&auto=format&fit=crop",
            description="Authentic shawarma serving with garlic dip and pickles.",
            is_veg=False,
            restaurant_id=restaurant.id # Use dynamic restaurant.id
        ),
        models.Food(
            food_name="Alfaham Chicken (Half)",
            food_category="Grills",
            food_price=240.0,
            food_quantity=40,
            image_url="https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?q=80&w=3000&auto=format&fit=crop",
            description="Charcoal grilled chicken with arabic spices.",
            is_veg=False,
            discount_percentage=10.0,
            restaurant_id=restaurant.id # Use dynamic restaurant.id
        ),
        models.Food(
            food_name="Hummus with Pita",
            food_category="Starters",
            food_price=140.0,
            food_quantity=60,
            image_url="https://images.unsplash.com/photo-1577906096429-f73c2c312435?q=80&w=2940&auto=format&fit=crop",
            description="Creamy chickpea dip with olive oil.",
            is_veg=True,
            restaurant_id=restaurant.id # Use dynamic restaurant.id
        ),
        models.Food(
            food_name="Falafel Wrap",
            food_category="Starters",
            food_price=120.0,
            food_quantity=60,
            image_url="https://images.unsplash.com/photo-1547055768-be2da1ce3875?q=80&w=2752&auto=format&fit=crop",
            description="Crispy falafel balls in a kuboos wrap.",
            is_veg=True,
            restaurant_id=restaurant.id # Use dynamic restaurant.id
        ),
        models.Food(
            food_name="Kunafa",
            food_category="Desserts",
            food_price=250.0,
            food_quantity=40,
            image_url="https://images.unsplash.com/photo-1579306194872-64d3b7bac4c2?q=80&w=2817&auto=format&fit=crop",
            description="Sweet cheese pastry soaked in syrup.",
            is_veg=True,
            restaurant_id=restaurant.id # Use dynamic restaurant.id
        ),
    ]

    for food in foods: 
        # Check if food already exists by name for this restaurant
        exists = db.query(models.Food).filter(
            models.Food.food_name == food.food_name,
            models.Food.restaurant_id == restaurant.id
        ).first()
        
        if not exists:
            # food is already an instantiated Model object from the list
            db.add(food)
            print(f"✅ Added Item: {food.food_name} (Discount: {food.discount_percentage}%)")
        else:
            # Update existing discount & Price
            exists.food_price = food.food_price
            exists.discount_percentage = food.discount_percentage
            exists.image_url = food.image_url # Update image too if changed
            db.add(exists)
            print(f"🔄 Updated Item: {exists.food_name}")
    
    db.commit()
    print("🎉 Arabian Menu Seeding Completed!")

    # 3. Add Marketing Banners
    print("🎨 Seeding Banners...")
    db.query(models.Banner).delete() # Clear existing
    banners = [
        models.Banner(
            title="Special Offer",
            image_url="https://images.unsplash.com/photo-1544025162-d7669d26560d?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80", # Feast
            deep_link="app://menu/offer",
            is_active=True,
            priority=1
        ),
        models.Banner(
            title="Mandi Special",
            image_url="https://images.unsplash.com/photo-1512485800893-ad60ab6da34a?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80", # Mandi rice
            deep_link="app://menu/mandi",
            is_active=True,
            priority=2
        ),
         models.Banner(
            title="Weekend Deal",
            image_url="https://images.unsplash.com/photo-1561758033-d8f19662cb23?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80", # Grill/Kebab
            deep_link="app://menu/grills",
            is_active=True,
            priority=3
        )
    ]
    db.add_all(banners)
    db.commit()
    print(f"✅ Created {len(banners)} Banners!")

    # 4. Add Coupons
    print("🎟️ Seeding Coupons...")
    db.query(models.Coupon).delete()
    coupons = [
        models.Coupon(
            code="OFFER50",
            discount_type="percentage",
            discount_value=50.0,
            min_order_value=0.0, # Removed restriction for easier claiming
            max_discount_amount=500.0,
            valid_from=func.now(),
            valid_until=func.now() + text("INTERVAL '30 days'"), # Valid for 30 days
            is_active=True
        ),
         models.Coupon(
            code="WELCOME",
            discount_type="flat",
            discount_value=20.0,
            min_order_value=50.0,
            is_active=True
        )
    ]
    db.add_all(coupons)
    db.commit()
    print(f"✅ Created {len(coupons)} Coupons!")

if __name__ == "__main__":
    seed_arabian_data()
