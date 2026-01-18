from sqlalchemy import Column, ForeignKey, Integer, String, Float, Boolean, DateTime, Date, Table as SATable
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base
from datetime import datetime

class User(Base):
    """
    Unified User model replacing 'Customer' from main_backend and 'User' from mobile_auth.
    """
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    email = Column(String, unique=True, index=True, nullable=True)
    phone_number = Column(String, unique=True, index=True, nullable=True)
    role = Column(Integer, default=0) # 0: Customer, 1: Admin/Kitchen
    city = Column(String, nullable=True)
    
    # Auth Provider Info
    external_id = Column(String, unique=True, nullable=True, index=True) # ID from Firebase/Auth0/etc.
    auth_provider = Column(String, default="local") # "firebase", "local", "google", "apple"
    password_hash = Column(String, nullable=True) # For Super Admin / Email Login
    
    # Relationships
    # Relationships
    # Relationships
    orders = relationship("Order", backref="user")
    # devices relationship handled by backref in UserDevice

class UserDevice(Base):
    __tablename__ = "user_devices"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey(User.id))
    fcm_token = Column(String, unique=True, index=True)
    device_type = Column(String, nullable=True) # android, ios, web
    last_active = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("User", backref="devices")

class Restaurant(Base):
    """
    New: Restaurant Entity for Multi-Vendor support.
    """
    __tablename__ = "restaurants"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    address = Column(String, nullable=True)
    image_url = Column(String, nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    is_active = Column(Boolean, default=True)
    
    # Owner/Manager (Optional link to User)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    
    # Relationships
    foods = relationship("Food", backref="restaurant")
    tables = relationship("Table", backref="restaurant")
    orders = relationship("Order", backref="restaurant")

class Auth(Base):
    """
    Auth model for OTP storage from mobile_auth.
    """
    __tablename__ = "auth"
    
    phone_number = Column(String, primary_key=True, index=True)
    verify_code = Column(String)
    token = Column(String, nullable=True)

class Food(Base):
    __tablename__ = "foods"

    food_id = Column(Integer, primary_key=True, index=True)
    
    # Multi-Vendor Link
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"), default=1) # Default to 1 for backward compat seed
    
    food_name = Column(String, index=True) # Removed unique=True to allow same name in diff restaurants
    food_category = Column(String, index=True) # Indexed for filtering
    food_price = Column(Float)
    food_quantity = Column(Integer)
    image_url = Column(String, nullable=True)
    description = Column(String, nullable=True) # New: Food Description
    is_veg = Column(Boolean, default=False) # New: Dietary preference
    rating = Column(Float, default=0.0) # New: Cached average rating

    orders = relationship("Order", backref="food")
    variants = relationship("FoodVariant", backref="food")
    favorites = relationship("Favorite", backref="food") # Relationship to favorites
    images = relationship("FoodImage", backref="food") # Multiple images

class FoodImage(Base):
    """
    Gallery images for a food item.
    """
    __tablename__ = "food_images"
    
    id = Column(Integer, primary_key=True, index=True)
    food_id = Column(Integer, ForeignKey("foods.food_id"))
    image_url = Column(String)

class UserAddress(Base):
    """
    User saved addresses (Home, Work, etc.)
    """
    __tablename__ = "user_addresses"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    label = Column(String) # "Home", "Office"
    address_line = Column(String)
    city = Column(String)
    zip_code = Column(String)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)

class Favorite(Base):
    """
    User Favorites/Likes
    """
    __tablename__ = "favorites"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    food_id = Column(Integer, ForeignKey("foods.food_id"))
    
    # Unique constraint to prevent duplicate likes
    # (handled in logic or we can add UniqueConstraint in args)

class FoodVariant(Base):
    """
    Variants for food items (e.g. Sizes: Half, Full; Portions: 500ml, 1L)
    """
    __tablename__ = "food_variants"
    
    id = Column(Integer, primary_key=True, index=True)
    food_id = Column(Integer, ForeignKey("foods.food_id"))
    variant_name = Column(String) # e.g. "Half", "Full", "500ml"
    variant_price = Column(Float) # Override price for this variant
    
    orders = relationship("Order", backref="variant")

class Order(Base):
    """
    Order model enhanced with status tracking for Kitchen Flow.
    Now supports Batch Orders (Cart Checkout).
    """
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    batch_id = Column(String, index=True) # UUID for grouping multiple items in one checkout
    
    # Multi-Vendor Link
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"), default=1)

    food_id = Column(Integer, ForeignKey("foods.food_id"))
    variant_id = Column(Integer, ForeignKey("food_variants.id"), nullable=True) 
    user_id = Column(Integer, ForeignKey("users.id"))
    address_id = Column(Integer, ForeignKey("user_addresses.id"), nullable=True) # Delivery Address
    
    quantity = Column(Integer)
    price_at_order = Column(Float) # Snapshot of price (base + variant)
    
    # Status: created, pending, progress, finished, dispatched, delivered, cancelled
    status = Column(String, default="created") 
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    feedbacks = relationship("Feedback", backref="order")
    # address = relationship("UserAddress")

class Table(Base):
    __tablename__ = "tables"

    id = Column(Integer, primary_key=True, index=True)
    
    # Multi-Vendor Link
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"), default=1)
    
    name = Column(Integer) # Removed Unique constraint to allow repeated table numbers globally (but unique per restaurant logic needed later)
    seat = Column(Integer)
    
    reservations = relationship("Reservation", backref="table")
    waitings = relationship("Waiting", backref="table")

class Reservation(Base):
    __tablename__ = "reservations"

    id = Column(Integer, primary_key=True, index=True)
    
    # Multi-Vendor Link
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"), default=1)
    
    user_id = Column(Integer, ForeignKey("users.id")) # Renamed from customer_id
    table_id = Column(Integer, ForeignKey("tables.id"))
    slot = Column(Integer)
    r_date = Column(Date)

class Feedback(Base):
    __tablename__ = "feedbacks"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id")) # Renamed from customer_id
    order_id = Column(Integer, ForeignKey("orders.id"))
    rate = Column(Integer)
    comment = Column(String)

class Waiting(Base):
    __tablename__ = "waitings"

    id = Column(Integer, primary_key=True, index=True)
    
    # Multi-Vendor Link
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"), default=1)
    
    user_id = Column(Integer, ForeignKey("users.id")) # Renamed from customer_id
    table_id = Column(Integer, ForeignKey("tables.id"))
    slot = Column(Integer)
    r_date = Column(Date)

# --- Marketing & Discovery Models ---

# Association Table for Collections <-> Foods
collection_foods = SATable(
    "collection_foods",
    Base.metadata,
    Column("collection_id", Integer, ForeignKey("collections.id")),
    Column("food_id", Integer, ForeignKey("foods.food_id"))
)

class Banner(Base):
    """
    Promotional Banners (Home Screen Slides)
    """
    __tablename__ = "banners"

    id = Column(Integer, primary_key=True, index=True)
    image_url = Column(String)
    title = Column(String, nullable=True) # "50% Off", "Diwali Special"
    deep_link = Column(String, nullable=True) # "app://restaurant/1", "app://collection/5"
    is_active = Column(Boolean, default=True)
    priority = Column(Integer, default=0) # For sorting

class Collection(Base):
    """
    Curated Lists (e.g. "Best Pizza", "Trending")
    """
    __tablename__ = "collections"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    image_url = Column(String, nullable=True)
    description = Column(String, nullable=True)
    
    # Many-to-Many Relationship
    foods = relationship("Food", secondary=collection_foods, backref="collections")

class Coupon(Base):
    """
    Discount Coupons
    """
    __tablename__ = "coupons"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String, unique=True, index=True) # e.g. "WELCOME50"
    discount_type = Column(String) # "percentage" or "flat"
    discount_value = Column(Float) # 50.0 (amount) or 10.0 (percent)
    min_order_value = Column(Float, default=0.0)
    max_discount_amount = Column(Float, nullable=True) # Cap for percentage, e.g. Max ₹100 off
    valid_from = Column(DateTime, default=func.now())
    valid_until = Column(DateTime)
    is_active = Column(Boolean, default=True)
