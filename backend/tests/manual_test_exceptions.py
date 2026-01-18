from fastapi.testclient import TestClient
from backend.main import app

client = TestClient(app)

def test_404_format():
    res = client.get("/non-existent-endpoint")
    assert res.status_code == 404
    data = res.json()
    print(f"404 Response: {data}")
    assert data["success"] is False
    assert data["message"] == "Not Found"

def test_validation_format():
    # Login with INVALID TYPE to trigger Pydantic 422
    # phone_number expects string, we send a list
    res = client.post("/auth/login", json={"phone_number": ["not", "a", "string"]}) 
    if res.status_code != 422:
        print(f"Expected 422, got {res.status_code}. Body: {res.text}")
    assert res.status_code == 422
    data = res.json()
    print(f"422 Response: {data}")
    assert data["success"] is False
    assert data["message"] == "Validation Error"

def test_success_format():
    res = client.get("/auth/hi")
    assert res.status_code == 200
    data = res.json()
    print(f"200 Response: {data}")
    # Should be wrapped
    assert data["success"] is True
    assert data["data"]["message"] == "Hi"

if __name__ == "__main__":
    test_404_format()
    test_validation_format()
    test_success_format()
