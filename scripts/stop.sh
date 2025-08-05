#!/bin/bash

# Stop all YTEmpire services

set -e

# Colors
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Stopping YTEmpire services...${NC}"

# Stop services
docker-compose down

echo -e "${RED}All services stopped.${NC}"
echo ""
echo "To remove volumes and data, run: docker-compose down -v"