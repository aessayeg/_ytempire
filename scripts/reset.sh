#!/bin/bash

# Reset YTEmpire environment to clean state

set -e

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}WARNING: This will reset your entire development environment!${NC}"
echo -e "${YELLOW}All data will be lost!${NC}"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Reset cancelled."
    exit 0
fi

echo -e "${BLUE}Resetting YTEmpire environment...${NC}"

# Stop and remove all containers, networks, and volumes
docker-compose down -v

# Remove all generated files
echo "Removing generated files..."
rm -rf logs/* uploads/* temp/* backups/*
rm -f nginx/ssl/*.pem
rm -rf monitoring/prometheus.yml monitoring/grafana/provisioning/datasources/prometheus.yml monitoring/filebeat.yml

# Remove node_modules if requested
read -p "Remove node_modules directories? (yes/no): " remove_node

if [ "$remove_node" == "yes" ]; then
    echo "Removing node_modules..."
    rm -rf frontend/node_modules backend/node_modules
fi

echo -e "${BLUE}Environment reset complete!${NC}"
echo ""
echo "Run './scripts/setup.sh' to reinitialize the environment."