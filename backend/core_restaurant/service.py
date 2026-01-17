from sqlalchemy.orm import Session
from datetime import datetime
from ..common import models, schemas

class CoreRestaurantService:
    def __init__(self, db: Session):
        self.db = db

    def get_foods(
        self, 
        skip: int = 0, 
        limit: int = 100, 
        search: str = None, 
        category: str = None,
        min_price: float = None,
        max_price: float = None,
        is_veg: bool = None,
        sort_by: str = None
    ):
        query = self.db.query(models.Food)
        
        # Filters
        if search:
            search_fmt = f"%{search}%"
            query = query.filter(
                (models.Food.food_name.ilike(search_fmt)) | 
                (models.Food.description.ilike(search_fmt))
            )
        if category:
            query = query.filter(models.Food.food_category == category)
        if min_price is not None:
            query = query.filter(models.Food.food_price >= min_price)
        if max_price is not None:
            query = query.filter(models.Food.food_price <= max_price)
        if is_veg is not None:
            query = query.filter(models.Food.is_veg == is_veg)
            
        # Sorting
        if sort_by == "price_low":
            query = query.order_by(models.Food.food_price.asc())
        elif sort_by == "price_high":
            query = query.order_by(models.Food.food_price.desc())
        elif sort_by == "rating":
            query = query.order_by(models.Food.rating.desc())
        # Default: food_id or relevance (handled by DB default usually)
            
        return query.offset(skip).limit(limit).all()

    def create_food(self, food: schemas.FoodCreate):
        # Create Food
        db_food = models.Food(
            food_name=food.food_name,
            food_category=food.food_category,
            food_price=food.food_price,
            food_quantity=food.food_quantity,
            image_url=food.image_url,
            description=food.description,
            is_veg=food.is_veg
        )
        self.db.add(db_food)
        self.db.commit()
        self.db.refresh(db_food)

        # Create Variants
        if food.variants:
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
        
        return db_food
        
    def checkout(self, checkout_req: schemas.CheckoutRequest, user_id: int, billing_service: 'BillingService'):
        import uuid
        batch_id = str(uuid.uuid4())
        total_items_price = 0.0
        
        # Verify Address if provided
        if checkout_req.address_id:
            addr = self.db.query(models.UserAddress).filter(
                models.UserAddress.id == checkout_req.address_id,
                models.UserAddress.user_id == user_id
            ).first()
            if not addr:
                raise ValueError("Invalid Address ID")

        # Process Items
        created_orders = []
        for item in checkout_req.items:
            food = self.get_food(item.food_id)
            if not food:
                continue
            
            price = food.food_price
            if item.variant_id:
                variant = self.get_variant(item.variant_id)
                if variant and variant.food_id == item.food_id:
                    price = variant.variant_price # Use variant price override if non-zero logic, or simple replacement
            
            # Snapshotted Price * Quantity
            item_total = price * item.quantity
            total_items_price += item_total
            
            db_order = models.Order(
                batch_id=batch_id,
                food_id=item.food_id,
                variant_id=item.variant_id,
                user_id=user_id,
                address_id=checkout_req.address_id,
                quantity=item.quantity,
                price_at_order=price,
                status="created"
            )
            self.db.add(db_order)
            created_orders.append(db_order)
            
        self.db.commit()
        
        # Calculate Coupons / Final Bill
        # Mocking BillingService logic here or calling it if available
        discount = 0.0
        if checkout_req.coupon_code:
            # Simple manual check for now or ensure BillingService has a method that doesn't rely on pre-saved orders yet?
            # For simplicity, we calculate manually here or reuse billing logic
            if checkout_req.coupon_code == "DIWALI10":
                discount = total_items_price * 0.10

        final_amount = total_items_price - discount
        
        # (Optional) We could create a "Bill" record now, or let the /bill/{user_id} endpoint aggregate later.
        # Returning summary.
        return schemas.BatchOrderSummary(
            batch_id=batch_id,
            total_amount=total_items_price,
            discount_amount=discount,
            final_amount=final_amount,
            status="created",
            message="Order placed successfully"
        )

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
        
        # Validate variant if provided
        if order.variant_id:
            variant = self.get_variant(order.variant_id)
            if not variant or variant.food_id != order.food_id:
                return None
            
        db_order = models.Order(
            food_id=order.food_id,
            variant_id=order.variant_id,
            user_id=user_id,
            quantity=order.quantity,
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
