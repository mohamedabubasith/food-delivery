import os
import sys

# Add the current directory to sys.path to import backend modules
sys.path.append(os.getcwd())

from backend.common.database import SessionLocal
from backend.common import models
from backend.core_restaurant.service import CoreRestaurantService

def test_rating():
    db = SessionLocal()
    service = CoreRestaurantService(db)
    
    # 1. Ensure a user exists (ID 3 from previous check)
    user = db.query(models.User).filter(models.User.id == 3).first()
    if not user:
        print("User 3 not found")
        return

    # 2. Ensure a food exists (ID 50)
    food = db.query(models.Food).filter(models.Food.food_id == 50).first()
    if not food:
        print("Food 50 not found")
        return

    # 3. Create a dummy order
    order = models.Order(
        restaurant_id=1,
        food_id=50,
        user_id=3,
        quantity=1,
        price_at_order=food.food_price,
        status="delivered"
    )
    db.add(order)
    db.commit()
    db.refresh(order)
    print(f"Created order {order.id}")

    # 4. Submit feedback
    try:
        result = service.submit_feedback(user_id=3, order_id=order.id, rate=5, comment="Excellent!")
        print(f"Submission result: {result}")
        
        # Verify food rating
        db.refresh(food)
        print(f"New Food Rating: {food.rating}")
        
    except Exception as e:
        print(f"Error submitting feedback: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    test_rating()
