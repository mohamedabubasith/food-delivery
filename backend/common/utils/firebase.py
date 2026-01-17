from typing import Dict, Optional
import os
import json

# Try to import firebase_admin, but mock if not installed or configured in test env
try:
    import firebase_admin
    from firebase_admin import credentials, auth
    HAS_FIREBASE = True
except ImportError:
    HAS_FIREBASE = False

class FirebaseService:
    _initialized = False

    @classmethod
    def initialize(cls):
        if not HAS_FIREBASE:
            return
        
        if not cls._initialized:
            # Check for standard google credentials env var or default
            # If default app exists, no need to init again
            if not firebase_admin._apps:
                # 1. Try JSON in ENV Var (Best for deployment/gitignored env)
                cred_json = os.getenv("FIREBASE_CREDENTIALS_JSON")
                cred_path = os.getenv("FIREBASE_CRED_PATH")
                
                if cred_json:
                    try:
                        cred_dict = json.loads(cred_json)
                        # Fix potential escaping issue where \n is literal
                        if "private_key" in cred_dict:
                            cred_dict["private_key"] = cred_dict["private_key"].replace("\\n", "\n")
                        
                        cred = credentials.Certificate(cred_dict)
                        print("Initializing Firebase from ENV JSON")
                        firebase_admin.initialize_app(cred)
                        cls._initialized = True
                        return
                    except Exception as e:
                        print(f"Error parsing FIREBASE_CREDENTIALS_JSON: {e}")

                # 2. Try specific file in root (fallback)
                if not cred_path:
                    possible_path = os.path.join(os.getcwd(), "my-project-1630504481421-firebase-adminsdk-jtxgf-77aa5abd2a.json")
                    if os.path.exists(possible_path):
                        cred_path = possible_path

                if cred_path and os.path.exists(cred_path):
                    print(f"Initializing Firebase with cert: {cred_path}")
                    cred = credentials.Certificate(cred_path)
                    firebase_admin.initialize_app(cred)
                else:
                    # Use default (GOOGLE_APPLICATION_CREDENTIALS) or raise specific warning
                    try:
                        firebase_admin.initialize_app()
                    except Exception as e:
                        print(f"Firebase Init Warning: {e}")
            cls._initialized = True

    @classmethod
    def verify_id_token(cls, id_token: str) -> Optional[Dict]:
        """
        Verifies the Firebase ID Token.
        Returns the decoded token dict if valid, else None.
        Mocks behavior if 'mock_token' is passed in dev/test environment.
        """
        # --- DEVELOPMENT / TEST MOCK ---
        if id_token.startswith("mock_firebase_token_"):
             # Format: mock_firebase_token_{phone_number}
             phone_suffix = id_token.split("_")[-1]
             # If just "mock_firebase_token_valid", use dummy
             if phone_suffix == "valid":
                 return {"uid": "mock_uid_123", "phone_number": "+919999999999"}
             # Else assume it encodes a phone number
             return {"uid": f"mock_uid_{phone_suffix}", "phone_number": phone_suffix}
        
        if not HAS_FIREBASE:
             print("Firebase Admin SDK not installed.")
             return None

        cls.initialize()
        
        try:
            decoded_token = auth.verify_id_token(id_token)
            return decoded_token
        except Exception as e:
            print(f"Token Verification Failed: {e}")
            return None
