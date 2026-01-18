from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse, Response
from .responses import success_response
import json

class ResponseWrapperMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        response = await call_next(request)

        # Skip non-success and already-handled errors
        if response.status_code >= 400:
            return response
            
        # Skip weird content types (like images, streams)
        if "application/json" not in response.headers.get("content-type", ""):
            return response

        # Read the response body
        response_body = [section async for section in response.body_iterator]
        response.body_iterator = iter(response_body)
        
        try:
            body_content = b"".join(response_body).decode()
            if not body_content:
                return response
                
            data = json.loads(body_content)
            
            # Use standard wrapper
            wrapped = success_response(data=data)
            
            return JSONResponse(
                content=wrapped,
                status_code=response.status_code,
                headers=dict(response.headers)
            )
        except Exception:
            # If parsing fails or anything goes wrong, return original
            return response
