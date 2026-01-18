import os
import sys

# Add backend to path
sys.path.append(os.getcwd())

from backend.common.database import SessionLocal
from backend.common import models
from backend.common_auth.service import AuthService

def seed_test_user():
    db = SessionLocal()
    try:
        phone = "9876543210"
        print(f"Checking for user {phone}...")
        
        service = AuthService(db)
        user = service.get_user_by_phone(phone)
        
        if user:
            print(f"✅ User already exists: {user.name} (Role: {user.role})")
        else:
            print("Creating new test user...")
            from backend.common import schemas
            
            new_user = schemas.UserCreate(
                name="Test Mobile User",
                phone_number=phone,
                city="Chennai"
            )
            created = service.create_user(new_user)
            print(f"✅ User created successfully: ID {created.id}")
            
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_test_user()
