from fastapi import FastAPI
from .common.database import engine, Base
from .common_auth import controller as auth_controller
from .core_restaurant import controller as core_controller
from .kitchen_service import controller as kitchen_controller
from .common.exceptions import add_exception_handlers
from .common.middleware import ResponseWrapperMiddleware

app = FastAPI(title="Unified Food Order & Delivery System")
add_exception_handlers(app)
app.add_middleware(ResponseWrapperMiddleware)

from fastapi.middleware.cors import CORSMiddleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create tables on startup
@app.on_event("startup")
def startup_event():
    Base.metadata.create_all(bind=engine)
    
    # Initialize Background Services
    from .common.utils.scheduler import start_scheduler
    from .common.utils.notification_service import initialize_firebase
    from .common.jobs import register_system_jobs
    
    start_scheduler()
    initialize_firebase()
    register_system_jobs()

    # Seed Default Data
    from .common.database import SessionLocal
    from .common.utils.seed_restaurant import seed_default_restaurant
    from .common_auth.service import AuthService
    import os

    db = SessionLocal()
    try:
        # 1. Default Restaurant
        seed_default_restaurant(db)
        
        # 2. Super Admin Bootstrap
        admin_email = os.getenv("SUPER_ADMIN_EMAIL", "admin@admin.com")
        admin_pass = os.getenv("SUPER_ADMIN_PASSWORD", "admin123")
        if admin_email and admin_pass:
            auth_service = AuthService(db)
            auth_service.create_super_admin(admin_email, admin_pass)
    finally:
        db.close()

@app.on_event("shutdown")
def shutdown_event():
    from .common.utils.scheduler import stop_scheduler
    stop_scheduler()

# Include Routers from Services
app.include_router(auth_controller.router)
app.include_router(core_controller.orders_router)
app.include_router(core_controller.menu_router)
app.include_router(core_controller.table_router)
app.include_router(core_controller.reservation_router)
app.include_router(core_controller.billing_router)
app.include_router(core_controller.restaurant_router)
app.include_router(kitchen_controller.router)

@app.get("/")
def root():
    return {"message": "Welcome to the Unified Food Ordering System API (Modular Services)"}
