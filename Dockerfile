
FROM python:3.9-slim

# Install UV for faster package installation
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY backend/requirements.txt .

# Install python dependencies using UV (System-wide)
RUN uv pip install --system --no-cache-dir -r requirements.txt

# Copy application code
COPY backend/ ./backend/
COPY .env .

# Set Python path
ENV PYTHONPATH=/app

# Expose port
EXPOSE 8000

# Run commands
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
