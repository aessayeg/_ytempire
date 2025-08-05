#!/bin/bash

# View logs for YTEmpire services

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

# Default to all services
SERVICE=$1

if [ -z "$SERVICE" ]; then
    echo -e "${BLUE}Showing logs for all services...${NC}"
    echo -e "${GREEN}Tip: Use './scripts/logs.sh <service>' to view specific service logs${NC}"
    echo -e "${GREEN}Available services: frontend, backend, postgresql, redis, nginx, pgadmin, mailhog${NC}"
    echo ""
    docker-compose logs -f --tail=100
else
    echo -e "${BLUE}Showing logs for $SERVICE...${NC}"
    docker-compose logs -f --tail=100 $SERVICE
fi