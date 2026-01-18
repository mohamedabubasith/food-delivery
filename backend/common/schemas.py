from typing import List, Optional
from pydantic import BaseModel, validator
from datetime import datetime, date

# --- User Schemas ---
class UserBase(BaseModel):
    name: str
    phone_number: Optional[str] = None
    email: Optional[str] = None
    city: Optional[str] = None

class UserCreate(UserBase):
    @validator("phone_number")
    def validate_phone_number(cls, v):
        if v and not v.isnumeric():
            raise ValueError("Phone number must be digits.")
        return v
    
    @validator("name")
    def validate_name(cls, v):
        if not v.strip():
            raise ValueError("Name cannot be empty.")
        return v

class User(UserBase):
    id: int
    role: int
    class Config:
        orm_mode = True

# --- Auth Schemas ---
class LoginRequest(BaseModel):
    # Unified Login Schema
    phone_number: Optional[str] = None # For legacy SMS flow
    token: Optional[str] = None # For Provider flow (Firebase)
    provider: Optional[str] = None # 'firebase', etc.

class AuthRequest(BaseModel):
    # For legacy SMS verification
    phone_number: str
    verify_code: str

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    phone_number: Optional[str] = None
    role: Optional[int] = None

# --- Restaurant Schemas ---
class RestaurantBase(BaseModel):
    name: str
    address: Optional[str] = None
    image_url: Optional[str] = None

class RestaurantCreate(RestaurantBase):
    pass

class Restaurant(RestaurantBase):
    id: int
    class Config:
        orm_mode = True

# --- Address Schemas ---
# ... (Address schemas unchanged) ...
class AddressBase(BaseModel):
    label: str
    address_line: str
    city: str
    zip_code: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class AddressCreate(AddressBase):
    pass

class Address(AddressBase):
    id: int
    user_id: int
    class Config:
        orm_mode = True

# --- Checkout Schemas ---
class CartItem(BaseModel):
    food_id: int
    variant_id: Optional[int] = None
    quantity: int

class CheckoutRequest(BaseModel):
    items: List[CartItem]
    address_id: Optional[int] = None
    coupon_code: Optional[str] = None
    restaurant_id: Optional[int] = 1 # Default to 1

class BatchOrderSummary(BaseModel):
    batch_id: str
    total_amount: float
    discount_amount: float
    final_amount: float
    status: str
    message: str

# --- Food Schemas ---
class FoodVariantBase(BaseModel):
    variant_name: str
    variant_price: float

class FoodVariantCreate(FoodVariantBase):
    pass

class FoodVariant(FoodVariantBase):
    id: int
    food_id: int
    class Config:
        orm_mode = True

class FoodBase(BaseModel):
    food_name: str
    food_category: str
    food_price: float
    food_quantity: int
    image_url: Optional[str] = None
    description: Optional[str] = None
    is_veg: bool = False
    restaurant_id: Optional[int] = 1 # Default to 1

class FoodCreate(FoodBase):
    variants: List[FoodVariantCreate] = []

class Food(FoodBase):
    food_id: int
    rating: float = 0.0
    variants: List[FoodVariant] = [] # Return variants
    # is_favorite: bool = False # TODO: Add this dynamically based on user context if needed
    
    class Config:
        orm_mode = True

# --- New: Search & Filter Schema ---
class MenuFilter(BaseModel):
    search: Optional[str] = None
    category: Optional[str] = None
    min_price: Optional[float] = None
    max_price: Optional[float] = None
    is_veg: Optional[bool] = None
    sort_by: Optional[str] = "relevance" # relevance, price_low, price_high, rating
    restaurant_id: Optional[int] = 1 # Default to 1

# --- Feedback Schemas ---
class FeedbackBase(BaseModel):
    order_id: int
    rate: int
    comment: str

class FeedbackCreate(FeedbackBase):
    pass

class Feedback(FeedbackBase):
    id: int
    user_id: int
    class Config:
        orm_mode = True

# --- Order Schemas ---
class OrderBase(BaseModel):
    food_id: int
    variant_id: Optional[int] = None
    quantity: int
    restaurant_id: Optional[int] = 1

class OrderCreate(OrderBase):
    pass

class OrderUpdateStatus(BaseModel):
    status: str

class Order(OrderBase):
    id: int
    user_id: int
    status: str
    created_at: Optional[datetime]
    updated_at: Optional[datetime]
    food: Optional[Food] = None
    variant: Optional[FoodVariant] = None
    feedbacks: List[Feedback] = []

    class Config:
        orm_mode = True

# --- Table Schemas ---
class TableBase(BaseModel):
    name: int
    seat: int
    restaurant_id: Optional[int] = 1

class TableCreate(TableBase):
    pass

class Table(TableBase):
    id: int
    class Config:
        orm_mode = True

# --- Reservation Schemas ---
class ReservationBase(BaseModel):
    table_id: int
    slot: int
    r_date: date
    restaurant_id: Optional[int] = 1

class ReservationCreate(ReservationBase):
    pass

class Reservation(ReservationBase):
    id: int
    user_id: int
    class Config:
        orm_mode = True

class CheckReservation(BaseModel):
    slot: int
    r_date: date
    restaurant_id: Optional[int] = 1

# --- Waiting Schemas ---
class WaitingBase(BaseModel):
    table_id: int
    slot: int
    r_date: date
    restaurant_id: Optional[int] = 1

class WaitingCreate(WaitingBase):
    pass

class Waiting(WaitingBase):
    id: int
    user_id: int
    class Config:
        orm_mode = True
