# Database Connection Guide

## Current Status
✅ Database is **running** and accessible
✅ Port **5435** is open and accepting connections
✅ **4 users** already exist in the database

## TablePlus Connection Settings

### Method 1: Create New Connection
1. Open TablePlus
2. Click **"Create a new connection"**
3. Select **PostgreSQL**
4. Fill in these details:
   - **Name**: Food Delivery DB (or any name you prefer)
   - **Host**: `127.0.0.1`
   - **Port**: `5435`
   - **User**: `postgres`
   - **Password**: `postgres`
   - **Database**: `food_db`
5. Click **"Test"** to verify connection
6. Click **"Connect"**

### Method 2: Connection String
If TablePlus supports connection strings, use:
```
postgresql://postgres:postgres@localhost:5435/food_db
```

## Troubleshooting

### If connection still fails:

1. **Check SSL Mode**: Try setting SSL mode to "Disable" or "Prefer"
2. **Check Firewall**: Ensure port 5435 isn't blocked by your firewall
3. **Verify Docker**: Run `docker ps` to ensure the container is running

### Alternative: Use Command Line
You can also query the database directly:
```bash
docker-compose exec db psql -U postgres -d food_db
```

Then run SQL queries like:
```sql
SELECT * FROM users;
```

## Quick Database Commands

```bash
# Count users
docker-compose exec db psql -U postgres -d food_db -c "SELECT COUNT(*) FROM users;"

# View all users
docker-compose exec db psql -U postgres -d food_db -c "SELECT id, name, phone_number, email, auth_provider FROM users;"

# View user creation timestamps
docker-compose exec db psql -U postgres -d food_db -c "SELECT id, name, created_at FROM users ORDER BY created_at DESC;"
```
