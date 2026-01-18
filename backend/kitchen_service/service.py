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
            
            # Send Notification
            try:
                from ..common.utils import notification_service
                devices = self.db.query(models.UserDevice).filter(models.UserDevice.user_id == order.user_id).all()
                for device in devices:
                    notification_service.send_push_notification(
                        token=device.fcm_token,
                        title=f"Order Update: {status.title()}",
                        body=f"Your order #{order.id} is now {status}.",
                        data={"order_id": str(order.id), "status": status}
                    )
            except Exception as e:
                print(f"Failed to send notification: {e}")
                
        return order
