from typing import Optional
from datetime import timedelta
from sqlalchemy.orm import Session
from ..common import models, schemas
from ..common.utils import sms, security
from ..common.utils.security import create_access_token, ACCESS_TOKEN_EXPIRE_MINUTES

class AuthService:
    def __init__(self, db: Session):
        self.db = db

    def get_user_by_phone(self, phone_number: str):
        return self.db.query(models.User).filter(models.User.phone_number == phone_number).first()

    def create_user(self, user: schemas.UserCreate):
        db_user = models.User(
            name=user.name,
            phone_number=user.phone_number,
            email=user.email,
            city=user.city,
            role=0
        )
        self.db.add(db_user)
        self.db.commit()
        self.db.refresh(db_user)
        return db_user

    def initiate_login(self, phone_number: str):
        code = sms.generate_verify_code()
        # Clean up old codes
        self.db.query(models.Auth).filter(models.Auth.phone_number == phone_number).delete()
        
        db_auth = models.Auth(phone_number=phone_number, verify_code=code)
        self.db.add(db_auth)
        self.db.commit()
        
        return sms.send_sms_verify(phone_number, code)

    def verify_login(self, phone_number: str, code: str):
        return self.db.query(models.Auth).filter(
            models.Auth.phone_number == phone_number,
            models.Auth.verify_code == code
        ).first()

    def login_with_provider(self, token: str, provider: str = "firebase") -> Optional[str]:
        """
        Generic login for external providers (Firebase, Google, etc).
        Supports lookup by UID, Email, or Phone.
        """
        uid = None
        phone_number = None
        email = None
        name = "User"
        
        if provider == "firebase":
            from ..common.utils.firebase import FirebaseService
            decoded = FirebaseService.verify_id_token(token)
            if decoded:
                uid = decoded.get("uid")
                phone_number = decoded.get("phone_number")
                email = decoded.get("email")
                if decoded.get("name"):
                    name = decoded.get("name")
                elif email:
                    name = email.split("@")[0]
        else:
            # Future providers can be added here
            pass
            
        if not uid:
            return None
            
        # Strategy:
        # 1. Find by External ID (Exact Match)
        user = self.db.query(models.User).filter(models.User.external_id == uid).first()
        
        if not user:
            # 2. Find by Email (Link Account)
            if email:
                user = self.db.query(models.User).filter(models.User.email == email).first()
                
            # 3. Find by Phone (Link Account)
            if not user and phone_number:
                user = self.get_user_by_phone(phone_number)
                
            if user:
                # Link existing user to this provider
                if not user.external_id:
                     user.external_id = uid
                if not user.email and email:
                    user.email = email
                user.auth_provider = provider
                self.db.commit()
            else:
                # 4. Create New User
                user = models.User(
                    phone_number=phone_number,
                    email=email,
                    name=name, 
                    external_id=uid,
                    auth_provider=provider,
                    role=0 
                )
                self.db.add(user)
                
                try:
                    self.db.commit()
                    self.db.refresh(user)
                except Exception:
                    # Handle potential duplicate phone/email race condition
                    self.db.rollback()
                    return None
        
        return self.generate_token(user)
            
    def generate_token(self, user: models.User):
        # Use User ID as the subject for stability
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": str(user.id)}, expires_delta=access_token_expires
        )
        return access_token

    def update_user_profile(self, user_id: int, update_data: schemas.UserCreate):
        user = self.db.query(models.User).filter(models.User.id == user_id).first()
        if not user:
            return None
            
        user.name = update_data.name
        if update_data.email:
            user.email = update_data.email
        if update_data.city:
            user.city = update_data.city
        if update_data.phone_number:
            user.phone_number = update_data.phone_number
        
        self.db.commit()
        self.db.refresh(user)
        return user

    def delete_address(self, user_id: int, address_id: int) -> bool:
        address = self.db.query(models.UserAddress).filter(
            models.UserAddress.id == address_id,
            models.UserAddress.user_id == user_id
        ).first()
        
        if address:
            self.db.delete(address)
            self.db.commit()
            return True
        return False

    def create_super_admin(self, email, password):
        """Bootstrap Super Admin if not exists"""
        existing = self.db.query(models.User).filter(models.User.email == email).first()
        if existing:
            return existing
            
        print(f"Creating Super Admin: {email}")
        from ..common.utils.security import get_password_hash
        user = models.User(
            name="Super Admin",
            email=email,
            role=1,
            auth_provider="local",
            password_hash=get_password_hash(password),
            phone_number="0000000000" # Dummy
        )
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def authenticate_user(self, email, password):
        """Verify email/password login"""
        user = self.db.query(models.User).filter(models.User.email == email).first()
        if not user:
            return None
        from ..common.utils.security import verify_password
        if not verify_password(password, user.password_hash):
            return None
        return user
    
    def promote_user(self, phone_number: str):
        """Promote a user to Admin (Role 1)"""
        user = self.get_user_by_phone(phone_number)
        if user:
            user.role = 1
            self.db.commit()
            self.db.refresh(user)
            return user
        return None
