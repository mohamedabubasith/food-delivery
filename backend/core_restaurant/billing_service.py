from sqlalchemy.orm import Session
from ..common import models

class BillingService:
    def __init__(self, db: Session):
        self.db = db

    def calculate_bill(self, user_id: int, coupon_code: str = None):
        # Get all orders for user (maybe filter by 'finished' or 'delivered' in real app)
        orders = self.db.query(models.Order).filter(models.Order.user_id == user_id).all()
        
        total = 0.0
        for order in orders:
            if order.food:
                total += order.food.food_price * order.quantity
        
        if coupon_code == "DIWALI10":
            total = total - (total * 0.1)
            
        return total
