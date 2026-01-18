import firebase_admin
from firebase_admin import credentials, messaging
import os
import logging

logger = logging.getLogger("notification")

_is_initialized = False

import base64
import json

def initialize_firebase():
    global _is_initialized
    if _is_initialized:
        return

    try:
        # 1. Try Base64 Env Var (Best for Cloud)
        cred_base64 = os.getenv("FIREBASE_CREDENTIALS_BASE64")
        if cred_base64:
            try:
                decoded = base64.b64decode(cred_base64)
                cred_dict = json.loads(decoded)
                cred = credentials.Certificate(cred_dict)
                firebase_admin.initialize_app(cred)
                _is_initialized = True
                logger.info("Firebase Admin Initialized via Base64")
                return
            except Exception as e:
                logger.error(f"Invalid Base64 Credentials: {e}")

        # 2. Try File Path Env Var (Good for Local)
        cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH")
        if cred_path and os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            _is_initialized = True
            logger.info("Firebase Admin Initialized via File Path")
            return
            
        # 3. Default (GCP magic or Mock)
        try:
            firebase_admin.get_app()
        except ValueError:
            firebase_admin.initialize_app()
                
        _is_initialized = True
        logger.info("Firebase Admin Initialized (Default/Mock)")
    except Exception as e:
        logger.error(f"Failed to initialize Firebase: {e}")

def send_push_notification(token: str, title: str, body: str, data: dict = None):
    """
    Send a push notification to a single device.
    """
    if not _is_initialized:
        logger.warning("Firebase not initialized. Skipping notification.")
        return False

    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            token=token,
        )
        response = messaging.send(message)
        logger.info(f"Successfully sent message: {response}")
        return True
    except Exception as e:
        logger.error(f"Error sending message: {e}")
        return False
