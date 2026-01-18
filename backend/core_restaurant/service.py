from sqlalchemy.orm import Session
from sqlalchemy import func, Float, cast
from typing import List, Optional
from datetime import datetime
from ..common import models, schemas

class CoreRestaurantService:
    def __init__(self, db: Session):
        self.db = db

    # --- Restaurant Management ---
    def get_restaurants(self, search: Optional[str] = None, lat: Optional[float] = None, lng: Optional[float] = None):
        query = self.db.query(models.Restaurant)
        
        if search:
            query = query.filter(models.Restaurant.name.ilike(f"%{search}%"))
        
        results = query.all()
        
        # Calculate Distance if User Location provided
        if lat is not None and lng is not None:
            import math
            def calculate_distance(r_lat, r_lng):
                if r_lat is None or r_lng is None:
                    return float('inf')
                # Haversine Formula
                R = 6371 # Earth radius in km
                d_lat = math.radians(r_lat - lat)
                d_lng = math.radians(r_lng - lng)
                a = math.sin(d_lat/2) * math.sin(d_lat/2) + \
                    math.cos(math.radians(lat)) * math.cos(math.radians(r_lat)) * \
                    math.sin(d_lng/2) * math.sin(d_lng/2)
                c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
                return R * c

            # Sort by distance
            results.sort(key=lambda r: calculate_distance(r.latitude, r.longitude))
            
        return results

    def get_restaurant_by_id(self, restaurant_id: int):
        return self.db.query(models.Restaurant).filter(models.Restaurant.id == restaurant_id).first()

    def create_restaurant(self, restaurant: schemas.RestaurantCreate):
        db_restaurant = models.Restaurant(
            name=restaurant.name,
            address=restaurant.address,
            image_url=restaurant.image_url,
            latitude=restaurant.latitude,
            longitude=restaurant.longitude
        )
        self.db.add(db_restaurant)
        self.db.commit()
        self.db.refresh(db_restaurant)
        return db_restaurant

    # --- Food Methods ---
    def get_foods(
        self, 
        skip: int = 0, 
        limit: int = 100, 
        search: Optional[str] = None, 
        category: Optional[str] = None,
        min_price: Optional[float] = None,
        max_price: Optional[float] = None,
        is_veg: Optional[bool] = None,
        sort_by: Optional[str] = None,
        restaurant_id: int = 1
    ):
        """
        Get foods for a specific restaurant with filters
        """
        query = self.db.query(models.Food).filter(models.Food.restaurant_id == restaurant_id)
        
        # Filters
        if search:
            query = query.filter(models.Food.food_name.ilike(f"%{search}%"))
        
        if category and category != "All":
             query = query.filter(models.Food.food_category == category)
             
        if min_price is not None:
            query = query.filter(models.Food.food_price >= min_price)
            
        if max_price is not None:
            query = query.filter(models.Food.food_price <= max_price)
            
        if is_veg is not None:
            query = query.filter(models.Food.is_veg == is_veg)
            
        if sort_by:
            if sort_by == "price_low":
                query = query.order_by(models.Food.food_price.asc())
            elif sort_by == "price_high":
                query = query.order_by(models.Food.food_price.desc())
            elif sort_by == "rating":
                query = query.order_by(models.Food.rating.desc())
            # "best_seller" would complex join with Order, skipping for now or mocking
            
        return query.offset(skip).limit(limit).all()

    def get_menu_meta(self):
        """
        Returns metadata for filters: Min/Max Price, All Categories.
        """
        from sqlalchemy import func
        min_price = self.db.query(func.min(models.Food.food_price)).scalar() or 0
        max_price = self.db.query(func.max(models.Food.food_price)).scalar() or 0
        categories = self.db.query(models.Food.food_category).distinct().all()
        # categories comes as list of tuples [('Pizza',), ('Burger',)]
        cat_list = [c[0] for c in categories if c[0]]
        
        return {
            "min_price": min_price,
            "max_price": max_price,
            "categories": cat_list
        }

    def create_food(self, food: schemas.FoodCreate):
        # Ensure restaurant_id is set
        r_id = food.restaurant_id if food.restaurant_id else 1
        
        db_food = models.Food(
            food_name=food.food_name, 
            food_category=food.food_category, 
            food_price=food.food_price, 
            food_quantity=food.food_quantity,
            image_url=food.image_url,
            description=food.description,
            is_veg=food.is_veg,
            restaurant_id=r_id
        )
        self.db.add(db_food)
        self.db.commit()
        self.db.refresh(db_food)
        
        if food.variants: # Keep the check for variants
            for variant in food.variants:
                db_variant = models.FoodVariant(
                    food_id=db_food.food_id,
                    variant_name=variant.variant_name,
                    variant_price=variant.variant_price
                )
                self.db.add(db_variant)
            
            self.db.commit()
            self.db.refresh(db_food) # Refresh to load variants
        return db_food

    async def create_food_with_images(self, food: schemas.FoodCreate, images: List):
        # 1. Create Food (without images first)
        db_food = self.create_food(food)
        
        # 2. Upload Images
        if images:
            from ..common.utils.storage import StorageService
            for idx, img_file in enumerate(images):
                url = await StorageService.upload_image(img_file)
                
                # Create FoodImage
                db_img = models.FoodImage(food_id=db_food.food_id, image_url=url)
                self.db.add(db_img)
                
                # Set first image as primary if not set
                if idx == 0 and not db_food.image_url:
                    db_food.image_url = url
            
            self.db.commit()
            self.db.refresh(db_food)
            
        return db_food

    # --- Marketing & Discovery ---
    def get_banners(self):
        return self.db.query(models.Banner).filter(models.Banner.is_active == True).order_by(models.Banner.priority.desc()).all()

    def create_banner(self, banner: schemas.BannerCreate):
        db_banner = models.Banner(**banner.model_dump())
        self.db.add(db_banner)
        self.db.commit()
        self.db.refresh(db_banner)
        return db_banner

    def get_collections(self):
        return self.db.query(models.Collection).all()

    def create_collection(self, collection: schemas.CollectionCreate):
        db_coll = models.Collection(
            title=collection.title,
            image_url=collection.image_url,
            description=collection.description
        )
        if collection.restaurant_ids:
            restaurants = self.db.query(models.Restaurant).filter(models.Restaurant.id.in_(collection.restaurant_ids)).all()
            db_coll.restaurants = restaurants
            
        self.db.add(db_coll)
        self.db.commit()
        self.db.refresh(db_coll)
        return db_coll
        
        return db_coll

    def get_coupons(self, active_only: bool = True):
        query = self.db.query(models.Coupon)
        if active_only:
            now = datetime.now()
            query = query.filter(
                models.Coupon.is_active == True,
                models.Coupon.valid_until >= now
            )
        return query.all()

    def create_coupon(self, coupon: schemas.CouponCreate):
        db_coupon = models.Coupon(**coupon.model_dump())
        self.db.add(db_coupon)
        self.db.commit()
        self.db.refresh(db_coupon)
        return db_coupon

    def validate_coupon(self, code: str, cart_total: float):
        now = datetime.now()
        coupon = self.db.query(models.Coupon).filter(
            models.Coupon.code == code,
            models.Coupon.is_active == True,
            models.Coupon.valid_until >= now
        ).first()

        if not coupon:
            raise ValueError("Invalid or Expired Coupon")

        if cart_total < coupon.min_order_value:
            raise ValueError(f"Minimum order value of {coupon.min_order_value} required")

        # Calculate Discount
        discount = 0.0
        if coupon.discount_type == "percentage":
            discount = (cart_total * coupon.discount_value) / 100
            if coupon.max_discount_amount:
                discount = min(discount, coupon.max_discount_amount)
        else: # flat
            discount = coupon.discount_value
        
        # Ensure discount doesn't exceed total
        discount = min(discount, cart_total)
        
        return discount, coupon

    # Updated Checkout with REAL Coupon Logic
    def checkout(self, checkout_req: schemas.CheckoutRequest, user_id: int, billing_service):
        """
        Process batch order checkout
        """
        import uuid
        total_amount = 0.0
        final_orders = []
        batch_id = str(uuid.uuid4())
        
        # Default restaurant ID from request or 1
        r_id = checkout_req.restaurant_id if checkout_req.restaurant_id else 1

        # Verify Address if provided
        if checkout_req.address_id:
            addr = self.db.query(models.UserAddress).filter(
                models.UserAddress.id == checkout_req.address_id,
                models.UserAddress.user_id == user_id
            ).first()
            if not addr:
                raise ValueError("Invalid Address ID")
        
        for item in checkout_req.items:
            # Create individual order entries
            order_create = schemas.OrderCreate(
                food_id=item.food_id,
                variant_id=item.variant_id,
                quantity=item.quantity,
                restaurant_id=r_id
            )
            # Logic to calculate price locally if create_order doesn't return it before commit? 
            # create_order commits and refreshes, so we get price back.
            db_order = self.create_order(order_create, user_id)
            if db_order:
                # Update batch details
                db_order.batch_id = batch_id
                db_order.address_id = checkout_req.address_id
                
                final_orders.append(db_order)
                if db_order.price_at_order and db_order.quantity:
                    total_amount += (db_order.price_at_order * db_order.quantity)
        
        self.db.commit()
        
        # Apply Logic for Coupon (REAL)
        discount = 0.0
        if checkout_req.coupon_code:
            try:
                discount, _ = self.validate_coupon(checkout_req.coupon_code, total_amount)
            except ValueError as e:
                # Propagate specific error (e.g. Min Order Value)
                raise ValueError(str(e))

        final_amount = total_amount - discount
        
        return {
            "batch_id": batch_id,
            "total_amount": total_amount,
            "discount_amount": discount,
            "final_amount": final_amount,
            "status": "success",
            "message": "Order placed successfully"
        }

    def toggle_favorite(self, user_id: int, food_id: int):
        existing = self.db.query(models.Favorite).filter(
            models.Favorite.user_id == user_id,
            models.Favorite.food_id == food_id
        ).first()
        
        if existing:
            self.db.delete(existing)
            self.db.commit()
            return {"status": "removed"}
        else:
            new_fav = models.Favorite(user_id=user_id, food_id=food_id)
            self.db.add(new_fav)
            self.db.commit()
            return {"status": "added"}
            
    def get_user_favorites(self, user_id: int):
        return self.db.query(models.Favorite).filter(models.Favorite.user_id == user_id).all()

    def get_food(self, food_id: int):
        return self.db.query(models.Food).filter(models.Food.food_id == food_id).first()

    def get_variant(self, variant_id: int):
        return self.db.query(models.FoodVariant).filter(models.FoodVariant.id == variant_id).first()

    def create_order(self, order: schemas.OrderCreate, user_id: int):
        # Validate food exists
        food = self.get_food(order.food_id)
        if not food:
            return None
        
        price = food.food_price
        
        # Validate variant if provided
        if order.variant_id:
            variant = self.get_variant(order.variant_id)
            if not variant or variant.food_id != order.food_id:
                return None
            price = variant.variant_price
            
        # Determine Restaurant ID
        # Prefer provided ID, fallback to Food's restaurant, fallback to 1
        r_id = order.restaurant_id if order.restaurant_id else (food.restaurant_id if food.restaurant_id else 1)
            
        db_order = models.Order(
            food_id=order.food_id,
            variant_id=order.variant_id,
            user_id=user_id,
            quantity=order.quantity,
            price_at_order=price,
            restaurant_id=r_id,
            status="created"
        )
        self.db.add(db_order)
        self.db.commit()
        self.db.refresh(db_order)
        return db_order

    def get_all_orders(self, skip: int = 0, limit: int = 100):
        return self.db.query(models.Order).offset(skip).limit(limit).all()

    def get_user_orders(self, user_id: int, skip: int = 0, limit: int = 100):
        return self.db.query(models.Order).filter(models.Order.user_id == user_id).offset(skip).limit(limit).all()

    def get_order_by_id(self, order_id: int):
        return self.db.query(models.Order).filter(models.Order.id == order_id).first()

    # --- Marketing & Discovery ---
    def get_banners(self):
        return self.db.query(models.Banner).filter(models.Banner.is_active == True).order_by(models.Banner.priority.desc()).all()

    def create_banner(self, banner: schemas.BannerCreate):
        db_banner = models.Banner(**banner.model_dump())
        self.db.add(db_banner)
        self.db.commit()
        self.db.refresh(db_banner)
        return db_banner

    def get_collections(self):
        return self.db.query(models.Collection).all()

    def create_collection(self, collection: schemas.CollectionCreate):
        db_coll = models.Collection(
            title=collection.title,
            image_url=collection.image_url,
            description=collection.description
        )
        if collection.food_ids:
            foods = self.db.query(models.Food).filter(models.Food.food_id.in_(collection.food_ids)).all()
            db_coll.foods = foods
            
        self.db.add(db_coll)
        self.db.commit()
        self.db.refresh(db_coll)
        self.db.refresh(db_coll)
        return db_coll
        
    def claim_coupon(self, user_id: int, code: str):
        now = datetime.now()
        coupon = self.db.query(models.Coupon).filter(
            models.Coupon.code == code,
            models.Coupon.is_active == True,
            models.Coupon.valid_until >= now
        ).first()

        if not coupon:
            raise ValueError("Invalid or Expired Coupon")

        # Check if already claimed
        existing = self.db.query(models.UserCoupon).filter(
            models.UserCoupon.user_id == user_id,
            models.UserCoupon.coupon_id == coupon.id
        ).first()

        if existing:
            raise ValueError("Coupon already claimed")

        user_coupon = models.UserCoupon(
            user_id=user_id,
            coupon_id=coupon.id
        )
        self.db.add(user_coupon)
        self.db.commit()
        self.db.refresh(user_coupon)
        return user_coupon

    def get_user_coupons(self, user_id: int):
        # Return claimed coupons that are not used and still valid
        now = datetime.now()
        return self.db.query(models.UserCoupon).join(models.Coupon).filter(
            models.UserCoupon.user_id == user_id,
            models.UserCoupon.is_used == False,
            models.Coupon.valid_until >= now,
            models.Coupon.is_active == True
        ).all()

    def submit_feedback(self, user_id: int, order_id: int, rate: int, comment: str):
        order = self.db.query(models.Order).filter(
            models.Order.id == order_id, 
            models.Order.user_id == user_id
        ).first()
        
        if not order:
            raise ValueError("Order not found or does not belong to user")
            
        existing = self.db.query(models.Feedback).filter(models.Feedback.order_id == order_id).first()
        if existing:
            existing.rate = rate
            existing.comment = comment
        else:
            feedback = models.Feedback(
                user_id=user_id,
                order_id=order_id,
                rate=rate,
                comment=comment
            )
            self.db.add(feedback)
        
        self.db.commit()
        
        # Update Food Rating Link
        food_id = order.food_id
        avg_rating = self.db.query(func.avg(cast(models.Feedback.rate, Float)))\
            .join(models.Order, models.Order.id == models.Feedback.order_id)\
            .filter(models.Order.food_id == food_id)\
            .scalar()
            
        if avg_rating is not None:
             food = self.get_food(food_id)
             if food:
                 food.rating = round(float(avg_rating), 1)
                 self.db.add(food)
                 self.db.commit()
                 
        return {"status": "success", "new_rating": round(float(avg_rating or 0), 1)}
