from datetime import datetime, timedelta
from typing import Optional
from jose import jwt, JWTError
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from .. import schemas, models, database

# Secret key for JWT encoding (should be in env vars in prod)
SECRET_KEY = "SECRET_SUPER_SECRET_KEY_CHANGE_ME"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 300

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/token")

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(database.get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        sub: str = payload.get("sub")
        if sub is None:
            raise credentials_exception
        # Token data now just holds the subject identifier
        token_data = schemas.TokenData(phone_number=sub) 
    except JWTError:
        raise credentials_exception
        
    # Logic: Try to find by ID (new standard) or Phone (legacy compatibility)
    user = None
    
    # Check if sub is digit (could be ID or numeric phone)
    # Strategy: 
    # 1. Try by ID if it looks like an ID (usually short integer, but phone is long)
    # BUT user ids are ints. `sub` is string in JWT.
    # Phone numbers are usually 10+ digits. IDs are usually smaller, but eventually grow.
    # Better approach: 
    # Since we are moving to ID as standard, let's assume if we can cast to int, we try ID lookup first.
    # However, phone "9999999999" is also a valid int.
    # DIFFERENTIATION: WE WILL PREFIX IDs in `sub`? No, simpler:
    # Look up by ID first. If not found, look up by phone.
    # Risk: User ID 1234567890 matches a phone number? Unlikely for now.
    
    # Best approach for migration:
    # If we find a user by ID, return it.
    # If not, try phone.
    
    if sub.isdigit():
        user = db.query(models.User).filter(models.User.id == int(sub)).first()
        
    if not user:
         user = db.query(models.User).filter(models.User.phone_number == sub).first()
         
    if user is None:
        raise credentials_exception
    return user

def get_current_active_kitchen_user(current_user: models.User = Depends(get_current_user)):
    # Role 1 is for admin/kitchen staff
    if current_user.role != 1:
        raise HTTPException(status_code=400, detail="Not a kitchen/admin user")
    return current_user
