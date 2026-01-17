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
        Currently supports: 'firebase'
        """
        uid = None
        phone_number = None
        
        if provider == "firebase":
            from ..common.utils.firebase import FirebaseService
            decoded = FirebaseService.verify_id_token(token)
            if decoded:
                uid = decoded.get("uid")
                phone_number = decoded.get("phone_number")
        else:
            # Future providers can be added here
            pass
            
        if not uid or not phone_number:
            return None
            
        # Check if user exists by External ID (Provider Agnostic User ID)
        user = self.db.query(models.User).filter(models.User.external_id == uid).first()
        
        if not user:
            # Check by phone to link accounts
            user = self.get_user_by_phone(phone_number)
            if user:
                # Link existing user
                user.external_id = uid
                user.auth_provider = provider
                self.db.commit()
            else:
                # Create new user
                user = models.User(
                    phone_number=phone_number,
                    name="User", 
                    external_id=uid,
                    auth_provider=provider,
                    role=0 
                )
                self.db.add(user)
                self.db.commit()
                self.db.refresh(user)
        
        return self.generate_token(user.phone_number)
            
    def generate_token(self, phone_number: str):
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": phone_number}, expires_delta=access_token_expires
        )
        return access_token
