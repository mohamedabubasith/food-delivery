from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.jobstores.sqlalchemy import SQLAlchemyJobStore
from ..database import engine
from datetime import datetime
import logging

logger = logging.getLogger("scheduler")

# Job Store (Persistent via Database)
jobstores = {
    'default': SQLAlchemyJobStore(engine=engine, tablename='scheduler_jobs')
}

scheduler = AsyncIOScheduler(jobstores=jobstores)

def start_scheduler():
    try:
        scheduler.start()
        logger.info("APScheduler Started")
    except Exception as e:
        logger.error(f"Failed to start APScheduler: {e}")

def stop_scheduler():
    try:
        scheduler.shutdown()
        logger.info("APScheduler Shutdown")
    except Exception as e:
        logger.error(f"Failed to stop APScheduler: {e}")

def schedule_task(func, trigger, **kwargs):
    """Generic helper to add jobs"""
    try:
        scheduler.add_job(func, trigger, **kwargs)
    except Exception as e:
        logger.error(f"Failed to schedule task: {e}")
