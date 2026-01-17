from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..common import models, schemas, database
from ..common.utils.security import get_current_active_kitchen_user
from .service import KitchenService

router = APIRouter(
    prefix="/kitchen",
    tags=["kitchen"]
)

@router.get("/orders", response_model=List[schemas.Order])
def read_kitchen_orders(
    status: str = "created",
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_active_kitchen_user)
):
    service = KitchenService(db)
    return service.get_orders_by_status(status)

@router.put("/orders/{order_id}/status", response_model=schemas.Order)
def update_order_status(
    order_id: int,
    status_update: schemas.OrderUpdateStatus,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_active_kitchen_user)
):
    service = KitchenService(db)
    order = service.update_order_status(order_id, status=status_update.status)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return order
