import sys
import os

# Add parent directory to path to allow imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from common import database, models
from common.utils import security

def reset_password():
    print("Connecting to database...")
    try:
        db = next(database.get_db())
        # Find by email admin@admin.com explicitly to be safe
        user = db.query(models.User).filter(models.User.email == "admin@admin.com").first()
        
        if not user:
            print("User admin@admin.com not found. Searching for any role 1 user...")
            user = db.query(models.User).filter(models.User.role == 1).first()

        if user:
            print(f"Found admin user: {user.email} (ID: {user.id})")
            new_password = "password123"
            user.password_hash = security.get_password_hash(new_password)
            db.commit()
            print(f"✅ Password successfully reset to: {new_password}")
        else:
            print("❌ No admin user found!")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    reset_password()
