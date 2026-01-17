from fastapi import FastAPI
from .common.database import engine, Base
from .common_auth import controller as auth_controller
from .core_restaurant import controller as core_controller
from .kitchen_service import controller as kitchen_controller

app = FastAPI(title="Unified Food Order & Delivery System")

# Create tables on startup
@app.on_event("startup")
def startup_event():
    Base.metadata.create_all(bind=engine)

# Include Routers from Services
app.include_router(auth_controller.router)
app.include_router(core_controller.orders_router)
app.include_router(core_controller.menu_router)
app.include_router(core_controller.table_router)
app.include_router(core_controller.reservation_router)
app.include_router(core_controller.billing_router)
app.include_router(kitchen_controller.router)

@app.get("/")
def root():
    return {"message": "Welcome to the Unified Food Ordering System API (Modular Services)"}
