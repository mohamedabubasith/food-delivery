from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..common import models, schemas, database
from ..common.utils.security import get_current_user
from .service import AuthService

router = APIRouter(
    prefix="/auth",
    tags=["auth"]
)

@router.post("/register", response_model=schemas.User)
def register(user: schemas.UserCreate, db: Session = Depends(database.get_db)):
    service = AuthService(db)
    if service.get_user_by_phone(user.phone_number):
        raise HTTPException(status_code=400, detail="Phone number already registered")
    return service.create_user(user)

@router.post("/login")
def login(req: schemas.LoginRequest, db: Session = Depends(database.get_db)):
    service = AuthService(db)
    
    # Check default provider from ENV or Request
    import os
    provider = req.provider or os.getenv("DEFAULT_AUTH_PROVIDER", "local")

    # Flow 1: External Provider (Firebase, etc)
    if provider != "local":
        if not req.token:
            raise HTTPException(status_code=400, detail="Token required for provider login")
        
        access_token = service.login_with_provider(req.token, provider, req.name)
        if not access_token:
            raise HTTPException(status_code=400, detail="Invalid Credentials")
            
        return {"access_token": access_token, "token_type": "bearer"}

    # Flow 2: Legacy Local OTP
    elif provider == "local" and req.phone_number:
        # OTP Flow
        user = service.get_user_by_phone(req.phone_number)
        if not user:
            # Auto-Signup (Zomato Style)
            user_create = schemas.UserCreate(
                name="Guest User", 
                phone_number=req.phone_number,
                city="Unknown"
            )
            user = service.create_user(user_create)
            
        if service.initiate_login(req.phone_number):
            return {"message": "Verification code sent"}
        else:
            raise HTTPException(status_code=500, detail="Failed to send SMS")

    # Flow 3: Email/Password (Super Admin)
    elif provider == "local" and req.email and req.password:
        user = service.authenticate_user(req.email, req.password)
        if not user:
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        token = service.generate_token(user)
        return {"access_token": token, "token_type": "bearer"}

    else:
         raise HTTPException(status_code=400, detail="Invalid login request")

@router.post("/token", response_model=schemas.Token)
def authenticate(auth_req: schemas.AuthRequest, db: Session = Depends(database.get_db)):
    service = AuthService(db)
    
    if not service.verify_login(auth_req.phone_number, auth_req.verify_code):
        raise HTTPException(status_code=400, detail="Invalid verification code")
    
    user = service.get_user_by_phone(auth_req.phone_number)
    if not user:
        # Auto-create user if they don't exist (Firebase Phone Auth flow)
        user_create = schemas.UserCreate(
            name="User",  # Will be updated via name input screen
            phone_number=auth_req.phone_number,
            city="Unknown"
        )
        user = service.create_user(user_create)
        if not user:
            raise HTTPException(status_code=500, detail="Failed to create user")

    access_token = service.generate_token(user)
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/addresses", response_model=schemas.Address)
def create_address(
    address: schemas.AddressCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    db_address = models.UserAddress(**address.dict(), user_id=current_user.id)
    db.add(db_address)
    db.commit()
    db.refresh(db_address)
    return db_address

@router.get("/addresses", response_model=List[schemas.Address])
def get_addresses(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    return db.query(models.UserAddress).filter(models.UserAddress.user_id == current_user.id).all()

@router.put("/me", response_model=schemas.User)
def update_profile(
    user_update: schemas.UserCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    service = AuthService(db)
    updated_user = service.update_user_profile(current_user.id, user_update)
    return updated_user

@router.put("/profile")
def update_profile_name(
    update_data: dict,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Update user profile (specifically name for now)"""
    if 'name' in update_data:
        current_user.name = update_data['name']
        db.commit()
        db.refresh(current_user)
    return {"message": "Profile updated successfully"}

@router.put("/addresses/{address_id}", response_model=schemas.Address)
def update_address(
    address_id: int,
    address_update: schemas.AddressCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    service = AuthService(db)
    updated = service.update_address(current_user.id, address_id, address_update)
    if updated:
        return updated
    raise HTTPException(status_code=404, detail="Address not found")

@router.post("/addresses/{address_id}/primary")
def set_primary_address(
    address_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    service = AuthService(db)
    if service.set_primary_address(current_user.id, address_id):
        return {"message": "Set as primary successfully"}
    raise HTTPException(status_code=404, detail="Address not found")

@router.delete("/addresses/{address_id}")
def delete_address(
    address_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    service = AuthService(db)
    if service.delete_address(current_user.id, address_id):
        return {"message": "Address deleted"}
    raise HTTPException(status_code=404, detail="Address not found")

@router.get("/me", response_model=schemas.User)
def read_users_me(current_user: models.User = Depends(get_current_user)):
    return current_user

# --- Legacy Compatibility Endpoints ---

@router.get("/whoiam")
def whoiam(current_user: models.User = Depends(get_current_user)):
    return {
        "id": current_user.id,
        "name": current_user.name,
        "phone_number": current_user.phone_number,
        "email": current_user.email,
        "admin": current_user.role == 1
    }

@router.get("/panel")
def panel(current_user: models.User = Depends(get_current_user)):
    return {
        "admin": current_user.role == 1,
        "name": current_user.name,
        "message": f"Welcome {current_user.name}."
    }

@router.get("/hi")
def hi():
    return {"message": "Hi"}

@router.post("/promote")
def promote_user(phone: str, current_user: models.User = Depends(get_current_user), db: Session = Depends(database.get_db)):
    # Standardize phone number (strip +91 if present) for consistency
    if phone.startswith("+91"):
        phone = phone[3:]
        
    if current_user.role != 1:
        raise HTTPException(status_code=403, detail="Admin privileges required")
        
    service = AuthService(db)
    user = service.promote_user(phone)
    if not user:
         raise HTTPException(status_code=404, detail="User not found")
    return {"message": f"User {user.name} promoted to Admin", "role": user.role}

@router.post("/device-token")
def register_device_token(token: str, device_type: str = "mobile", current_user: models.User = Depends(get_current_user), db: Session = Depends(database.get_db)):
    """Register FCM Token for Push Notifications"""
    # Check if token exists
    existing = db.query(models.UserDevice).filter(models.UserDevice.fcm_token == token).first()
    if existing:
        existing.user_id = current_user.id # Update owner if changed
        existing.last_active = datetime.utcnow()
    else:
        new_device = models.UserDevice(
            user_id=current_user.id,
            fcm_token=token,
            device_type=device_type
        )
        db.add(new_device)
    
    db.commit()
    return {"message": "Device registered"}
