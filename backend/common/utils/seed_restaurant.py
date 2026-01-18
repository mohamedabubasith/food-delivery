from sqlalchemy.orm import Session
from .. import models

def seed_default_restaurant(db: Session):
    """
    Ensure Default Restaurant (ID 1) exists for backward compatibility.
    """
    default_restaurant = db.query(models.Restaurant).filter(models.Restaurant.id == 1).first()
    if not default_restaurant:
        default_restaurant = models.Restaurant(
            id=1,
            name="Generic Foods",
            address="123 Main St, Tech City",
            image_url="http://mock-cloud/restaurant.jpg"
        )
        db.add(default_restaurant)
        db.commit()
        db.refresh(default_restaurant)
        
        # FIX: Update Postgres Sequence to avoid IntegrityError on next insert
        try:
            from sqlalchemy import text
            db.execute(text("SELECT setval('restaurants_id_seq', (SELECT MAX(id) FROM restaurants));"))
            db.commit()
        except Exception as e:
            print(f"Warning: Could not update sequence (might be SQLite?): {e}")

    return default_restaurant
