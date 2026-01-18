from sqlalchemy.orm import Session
from datetime import datetime
from ..common import models

class KitchenService:
    def __init__(self, db: Session):
        self.db = db

    def get_orders_by_status(self, status: str, restaurant_id: int = 1):
        return self.db.query(models.Order).filter(
            models.Order.status == status,
            models.Order.restaurant_id == restaurant_id
        ).all()

    def update_order_status(self, order_id: int, status: str):
        order = self.db.query(models.Order).filter(models.Order.id == order_id).first()
        if order:
            order.status = status
            order.updated_at = datetime.utcnow()
            self.db.commit()
            self.db.refresh(order)
        return order
