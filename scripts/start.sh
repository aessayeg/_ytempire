#!/bin/bash

# Start all YTEmpire services

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Starting YTEmpire services...${NC}"

# Start services
docker-compose up -d

# Wait for services to be ready
echo -e "${BLUE}Waiting for services to be healthy...${NC}"
sleep 5

# Show running services
echo -e "${GREEN}Running services:${NC}"
docker-compose ps

echo -e "${GREEN}YTEmpire services started!${NC}"
echo ""
echo "Access URLs:"
echo "  Frontend:        http://localhost:3000"
echo "  Backend API:     http://localhost:5000"
echo "  pgAdmin:         http://localhost:8080"
echo "  Redis Commander: http://localhost:8081"
echo "  MailHog:         http://localhost:8025"