from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File, Form
from sqlalchemy.orm import Session
from datetime import date
from ..common import models, schemas, database
from ..common.utils.security import get_current_user, get_current_active_kitchen_user
from ..common.utils.storage import StorageService
from .service import CoreRestaurantService
from .table_service import TableService
from .billing_service import BillingService

orders_router = APIRouter(prefix="/orders", tags=["orders"])
menu_router = APIRouter(prefix="/menu", tags=["menu"])
table_router = APIRouter(prefix="/tables", tags=["tables"])
reservation_router = APIRouter(prefix="/reservations", tags=["reservations"])
billing_router = APIRouter(prefix="/bill", tags=["billing"])
restaurant_router = APIRouter(prefix="/restaurants", tags=["restaurants"])

# --- RESTAURANT ROUTES ---
@restaurant_router.get("/", response_model=List[schemas.Restaurant])
def get_restaurants(
    search: Optional[str] = Query(None, description="Search by name"),
    db: Session = Depends(database.get_db)
):
    service = CoreRestaurantService(db)
    return service.get_restaurants(search)

@restaurant_router.get("/{restaurant_id}", response_model=schemas.Restaurant)
def get_restaurant(
    restaurant_id: int,
    db: Session = Depends(database.get_db)
):
    service = CoreRestaurantService(db)
    res = service.get_restaurant_by_id(restaurant_id)
    if not res:
        raise HTTPException(status_code=404, detail="Restaurant not found")
    return res

@restaurant_router.post("/", response_model=schemas.Restaurant)
def create_restaurant(
    restaurant: schemas.RestaurantCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_active_kitchen_user) # Admin only
):
    service = CoreRestaurantService(db)
    return service.create_restaurant(restaurant)

# --- MENU ROUTES ---
@menu_router.post("/upload-image")
async def upload_food_image(
    file: UploadFile = File(...),
    current_user: models.User = Depends(get_current_active_kitchen_user)
):
    url = await StorageService.upload_image(file)
    return {"image_url": url}

@menu_router.get("/", response_model=List[schemas.Food])
def read_menu(
    skip: int = 0, 
    limit: int = 100,
    search: Optional[str] = Query(None, description="Search by name or description"),
    category: Optional[str] = Query(None, description="Filter by category"),
    min_price: Optional[float] = Query(None, description="Min price"),
    max_price: Optional[float] = Query(None, description="Max price"),
    is_veg: Optional[bool] = Query(None, description="Filter by dietary preference"),
    sort_by: Optional[str] = Query(None, description="Sort: price_low, price_high, rating"),
    db: Session = Depends(database.get_db)
):
    service = CoreRestaurantService(db)
    return service.get_foods(
        skip=skip, limit=limit, 
        search=search, category=category, 
        min_price=min_price, max_price=max_price, 
        is_veg=is_veg, sort_by=sort_by
    )

@menu_router.post("/{food_id}/favorite")
def toggle_good_favorite(
    food_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    service = CoreRestaurantService(db)
    return service.toggle_favorite(user_id=current_user.id, food_id=food_id)

@menu_router.get("/favorites")
def get_my_favorites(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
    # response_model to be defined, currently using generic list
):
    service = CoreRestaurantService(db)
    # Depending on schema, we might need a response model that returns Food objects
    favorites = service.get_user_favorites(user_id=current_user.id)
    # Return list of food IDs or full objects? 
    # For now, let's return list of Food objects using the relationship
    return [fav.food for fav in favorites]

@menu_router.post("/", response_model=schemas.Food)
async def create_food_item(
    food_data: str = Form(...),
    images: List[UploadFile] = File(None),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_active_kitchen_user)
):
    import json
    service = CoreRestaurantService(db)
    
    # Parse JSON
    try:
        data = json.loads(food_data)
        food_create = schemas.FoodCreate(**data)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid JSON: {str(e)}")
        
    return await service.create_food_with_images(food_create, images)

# --- BILLING ROUTES ---
@billing_router.get("/{user_id}")
def get_bill(
    user_id: int, 
    coupon_code: Optional[str] = None, 
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    # Only allow user to see their own bill or admin
    if current_user.role != 1 and current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    service = BillingService(db)
    return {"total_amount": service.calculate_bill(user_id, coupon_code)}

# --- TABLE ROUTES ---
@table_router.get("/", response_model=List[schemas.Table])
def get_tables(db: Session = Depends(database.get_db)):
    service = TableService(db)
    return service.get_tables()

@table_router.post("/", response_model=schemas.Table)
def create_table(
    table: schemas.TableCreate, 
    db: Session = Depends(database.get_db), 
    current_user: models.User = Depends(get_current_active_kitchen_user)
):
    service = TableService(db)
    return service.create_table(table)

# --- RESERVATION ROUTES ---
@reservation_router.get("/", response_model=List[schemas.Reservation])
def get_reservations(db: Session = Depends(database.get_db)):
    service = TableService(db)
    return service.get_reservations()

@reservation_router.post("/check")
def check_availability(
    slot: int, r_date: date, person: int, 
    db: Session = Depends(database.get_db)
):
    service = TableService(db)
    tables = service.check_availability(slot, r_date, person)
    return tables

@reservation_router.post("/", response_model=schemas.Reservation)
def create_reservation(
    res: schemas.ReservationCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    service = TableService(db)
    result = service.create_reservation(res, user_id=current_user.id)
    if not result:
        raise HTTPException(status_code=400, detail="Table not available")
    return result

@reservation_router.delete("/{r_id}")
def delete_reservation(
    r_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    service = TableService(db)
    # TODO: Add ownership check logic here if strict
    if service.delete_reservation(r_id):
        return {"message": "Deleted"}
    raise HTTPException(status_code=404, detail="Not found")

# --- ORDER ROUTES ---
@orders_router.post("/checkout", response_model=schemas.BatchOrderSummary)
def checkout_orders(
    checkout_req: schemas.CheckoutRequest,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    service = CoreRestaurantService(db)
    try:
        # Mock billing service pass or None for now
        return service.checkout(checkout_req, current_user.id, None) 
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@orders_router.post("/", response_model=schemas.Order)
def create_order(
    order: schemas.OrderCreate, 
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    service = CoreRestaurantService(db)
    result = service.create_order(order, user_id=current_user.id)
    if not result:
        raise HTTPException(status_code=404, detail="Food item not found")
    return result

@orders_router.get("/", response_model=List[schemas.Order])
def read_orders(
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    service = CoreRestaurantService(db)
    if current_user.role == 1:
        return service.get_all_orders(skip=skip, limit=limit)
    else:
        return service.get_user_orders(user_id=current_user.id, skip=skip, limit=limit)

@orders_router.get("/{order_id}", response_model=schemas.Order)
def read_order(
    order_id: int, 
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    service = CoreRestaurantService(db)
    order = service.get_order_by_id(order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    
    if current_user.role != 1 and order.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to view this order")
        
    return order
