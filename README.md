# Fast Food Delivery Backend

A robust, containerized Fast API backend for a Multi-Vendor Food Delivery application (similar to Zomato/UberEats).

## 🚀 Features

*   **Multi-Vendor Marketplace**: Support for multiple restaurants, each with their own menu, tables, and orders.
*   **Authentication**: Unified login flow supporting legacy SMS OTP and Firebase Authentication.
*   **Storage**: Integrated **MinIO** for S3-compatible object storage (food images, etc.).
*   **Order Management**: Complete status tracking (Created -> Cooking -> Dispatched -> Delivered).
*   **Table Reservations**: Real-time table availability checking and booking.
*   **Batch Checkout**: Cart functionality with coupon support.
*   **Containerized**: Fully Dockerized setup with PostgreSQL and MinIO.

## 🛠️ Tech Stack

*   **Framework**: FastAPI (Python 3.9+)
*   **Database**: PostgreSQL 13 (via SQLAlchemy ORM)
*   **Storage**: MinIO (S3 Compatible)
*   **Containerization**: Docker & Docker Compose
*   **Package Manager**: `uv` (for fast builds)
*   **Testing**: Pytest

## ⚡ Quick Start (Docker)

The easiest way to run the application is using Docker Compose.

1.  **Clone the repository**
    ```bash
    git clone https://github.com/mohamedabubasith/food-delivery.git
    cd food-delivery
    ```

2.  **Configure Environment**
    Create a `.env` file in the root directory (see `.env.example` if available, or use defaults):
    ```env
    DATABASE_URL=postgresql://postgres:postgres@db:5432/food_db
    SECRET_KEY=your_secret_key
    DEFAULT_AUTH_PROVIDER=firebase
    
    # MinIO Config (Internal Docker Networking)
    MINIO_ENDPOINT=minio:9000
    MINIO_ROOT_USER=minioadmin
    MINIO_ROOT_PASSWORD=minioadmin
    MINIO_BUCKET=food-images
    MINIO_SECURE=False
    MINIO_EXTERNAL_ENDPOINT=http://localhost:9000
    ```

3.  **Run with Docker Compose**
    ```bash
    docker-compose up -d --build
    ```
    *   Backend: [http://localhost:8000](http://localhost:8000)
    *   MinIO Console: [http://localhost:9001](http://localhost:9001) (User/Pass: `minioadmin`)
    *   API Docs (Swagger): [http://localhost:8000/docs](http://localhost:8000/docs)

## 🧪 Testing

The project includes a comprehensive test suite covering all endpoints.

### Running Tests (Local)
Ensure you have dependencies installed:
```bash
pip install -r backend/requirements.txt
```

Run tests using pytest:
```bash
export PYTHONPATH=$PYTHONPATH:.
python3 -m pytest backend/tests/
```

## 📂 Project Structure

*   `backend/`: Source code
    *   `common/`: Shared models, schemas, and utils (DB, MinIO, Auth).
    *   `common_auth/`: Authentication logic.
    *   `core_restaurant/`: Core logic (Food, Menu, Orders, Checkout).
    *   `kitchen_service/`: Kitchen display system logic.
    *   `tests/`: Integration tests.
*   `docker-compose.yml`: Service orchestration.
*   `Dockerfile`: Backend image definition.

## 📦 MinIO Integration

The backend automatically attempts to create the `food-images` bucket on startup.
*   **Internal Access**: Backend talks to MinIO via `minio:9000`.
*   **External Access**: Public URLs are generated using `http://localhost:9000` (configurable via `MINIO_EXTERNAL_ENDPOINT`).

## 🔑 Authentication

*   **OTP**: Send `phone_number` to `/auth/login` (Provider: `local`) to trigger SMS (mocked in logs).
*   **Firebase**: Send `token` to `/auth/login` (Provider: `firebase`) for verified login.