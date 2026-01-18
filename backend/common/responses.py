from typing import Generic, TypeVar, Optional, Any
from pydantic import BaseModel

T = TypeVar("T")

class APIResponse(BaseModel, Generic[T]):
    success: bool
    message: str
    data: Optional[T] = None
    error: Optional[Any] = None

def success_response(data: Any = None, message: str = "Success"):
    return {
        "success": True,
        "message": message,
        "data": data,
        "error": None
    }

def error_response(message: str, error: Any = None, status_code: int = 400):
    # Note: Status code is handled by the framework response, 
    # but the body follows this structure.
    return {
        "success": False,
        "message": message,
        "data": None,
        "error": error
    }
