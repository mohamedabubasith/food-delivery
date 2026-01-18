from datetime import datetime, timedelta
from .database import SessionLocal
from . import models
from .utils import scheduler

def cancel_pending_orders_job():
    """Calculates orders stuck in 'created' state for > 30 mins and cancels them."""
    db = SessionLocal()
    try:
        # 30 minutes ago
        timeout_threshold = datetime.utcnow() - timedelta(minutes=30)
        
        pending_orders = db.query(models.Order).filter(
            models.Order.status == 'created', 
            models.Order.created_at < timeout_threshold
        ).all()
        
        if pending_orders:
            print(f"Found {len(pending_orders)} stale orders to cancel.")
            for order in pending_orders:
                order.status = 'cancelled'
                # Optionally send push notification here too
            
            db.commit()
    except Exception as e:
        print(f"Error in auto-cancel job: {e}")
    finally:
        db.close()

def register_system_jobs():
    """Register all system maintenance jobs."""
    # Run every 5 minutes
    scheduler.schedule_task(
        cancel_pending_orders_job, 
        'interval', 
        minutes=5, 
        id='auto_cancel_orders', 
        replace_existing=True
    )
