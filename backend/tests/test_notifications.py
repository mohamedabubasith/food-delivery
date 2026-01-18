from fastapi.testclient import TestClient
from backend.main import app
from backend.common import models
from backend.common.database import Base, engine, get_db, SessionLocal
from backend.common.utils import scheduler, notification_service
from unittest.mock import patch, MagicMock
import pytest

client = TestClient(app)

@pytest.fixture(scope="function")
def db_session():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)

def test_device_registration(db_session):
    # Setup User
    user = models.User(name="Test User", phone_number="1234567890", role=0)
    db_session.add(user)
    db_session.commit()
    
    from backend.common.utils import security
    token = security.create_access_token(data={"sub": str(user.id)})
    headers = {"Authorization": f"Bearer {token}"}
    
    # Register Token
    # Note: Controller expects query params by default for singular types
    res = client.post("/auth/device-token?token=fcm_mock_token&device_type=android", headers=headers)
    
    assert res.status_code == 200
    assert res.json()["data"]["message"] == "Device registered"
    
    # Verify DB
    db_session.expire_all() # Force reload from DB
    count = db_session.query(models.UserDevice).count()
    assert count == 1
    
    device = db_session.query(models.UserDevice).first()
    assert device is not None
    assert device.fcm_token == "fcm_mock_token"
    assert device.user_id == user.id

def test_scheduler_wrapper():
    # Mock adding job
    with patch.object(scheduler.scheduler, "add_job") as mock_add:
        def dummy_task(): pass
        scheduler.schedule_task(dummy_task, "interval", minutes=10)
        mock_add.assert_called_once()

def test_notification_send():
    # Mock Firebase
    with patch("firebase_admin.messaging.send") as mock_send:
        mock_send.return_value = "msg_id_123"
        
        # Initialize (Mocked)
        with patch("firebase_admin.get_app"): 
            notification_service._is_initialized = True
            
            success = notification_service.send_push_notification(
                token="test_token",
                title="Hello",
                body="World"
            )
            
            assert success is True
            mock_send.assert_called_once()
