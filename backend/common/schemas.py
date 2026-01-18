from typing import List, Optional
from pydantic import BaseModel, validator, ConfigDict
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
        import re
        if not v:
            return v
        # Normalize: Remove spaces, dashes
        v = v.replace(" ", "").replace("-", "")
        # Check for +91 or just 10 digits
        if v.startswith("+91"):
            v = v[3:]
        
        # Indian Mobile: 10 digits, starts with 6-9
        if not re.match(r"^[6-9]\d{9}$", v):
             raise ValueError("Phone number must be a valid 10-digit Indian mobile number (e.g., 9876543210).")
        return v
    
    @validator("name")
    def validate_name(cls, v):
        if not v.strip():
            raise ValueError("Name cannot be empty.")
        return v

    @validator("city")
    def validate_city(cls, v):
        # Optional: could enforce list of Indian cities, but free text is fine for now
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
    email: Optional[str] = None
    password: Optional[str] = None
    name: Optional[str] = None # For Google Sign-In displayName

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
    latitude: Optional[float] = None
    longitude: Optional[float] = None

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

    @validator("zip_code")
    def validate_pincode(cls, v):
        if not v.isdigit() or len(v) != 6:
            raise ValueError("Zip code must be a valid 6-digit Indian Pincode.")
        return v

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

class FoodImageBase(BaseModel):
    image_url: str

class FoodImage(FoodImageBase):
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
    discount_percentage: float = 0.0 # New field
    restaurant_id: Optional[int] = 1 # Default to 1

class FoodCreate(FoodBase):
    variants: List[FoodVariantCreate] = []

class Food(FoodBase):
    food_id: int
    rating: float = 0.0
    variants: List[FoodVariant] = [] # Return variants
    images: List[FoodImage] = [] # Multiple images
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

    model_config = ConfigDict(from_attributes=True)

# --- Marketing Schemas ---

class BannerBase(BaseModel):
    image_url: str
    title: Optional[str] = None
    deep_link: Optional[str] = None
    is_active: bool = True
    priority: int = 0

class BannerCreate(BannerBase):
    pass

class Banner(BannerBase):
    id: int
    model_config = ConfigDict(from_attributes=True)

class CollectionBase(BaseModel):
    title: str
    image_url: Optional[str] = None
    description: Optional[str] = None

class CollectionCreate(CollectionBase):
    food_ids: List[int] = []

class Collection(CollectionBase):
    id: int
    foods: List[Food] = [] # Nested objects
    model_config = ConfigDict(from_attributes=True)

class CouponBase(BaseModel):
    code: str
    discount_type: str # "percentage" or "flat"
    discount_value: float
    min_order_value: float = 0.0
    max_discount_amount: Optional[float] = None
    valid_until: datetime
    is_active: bool = True

class CouponCreate(CouponBase):
    pass

class Coupon(CouponBase):
    id: int
    model_config = ConfigDict(from_attributes=True)

class CouponApplyRequest(BaseModel):
    code: str
    cart_total: float

class UserCouponBase(BaseModel):
    user_id: int
    coupon_id: int
    is_used: bool = False

class UserCouponCreate(BaseModel):
    code: str # User claims by Code

class UserCoupon(UserCouponBase):
    id: int
    coupon: Coupon # Nested coupon details
    claimed_at: datetime
    model_config = ConfigDict(from_attributes=True)
