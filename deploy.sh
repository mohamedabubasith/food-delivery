#!/bin/bash

# Fast Food Backend - Auto Deployment Script

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting Deployment Process...${NC}"

# 1. Pull Latest Changes
echo -e "${YELLOW}📥 Pulling latest code from 'main' branch...${NC}"
git pull origin main

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Git pull failed! Please check your git configuration.${NC}"
    exit 1
fi

# 2. Check for .env file
if [ ! -f .env ]; then
    echo -e "${RED}❌ Error: .env file is missing!${NC}"
    echo -e "${YELLOW}Please create a .env file with your production secrets before deploying.${NC}"
    echo "Example: cp .env.example .env"
    exit 1
fi

# 3. Rebuild and Restart Containers
echo -e "${YELLOW}🐳 Rebuilding and restarting Docker containers...${NC}"
docker-compose down
docker-compose up -d --build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Deployment Successful!${NC}"
    echo "Backend is running and accessible."
    docker-compose ps
else
    echo -e "${RED}❌ Docker deployment failed!${NC}"
    exit 1
fi
