#!/bin/bash
# YTEmpire Database Setup Script
# Quick setup for development environment

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}YTEmpire Database Setup${NC}"
echo "========================"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running!${NC}"
    echo "Please start Docker Desktop and try again."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: docker-compose not found!${NC}"
    exit 1
fi

# Navigate to project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Check if docker-compose.db.yml exists
if [ ! -f "docker-compose.db.yml" ]; then
    echo -e "${RED}Error: docker-compose.db.yml not found!${NC}"
    exit 1
fi

# Stop any existing containers
echo -e "${YELLOW}Stopping existing containers...${NC}"
docker-compose -f docker-compose.db.yml down

# Remove old volumes (optional - commented out for safety)
# echo -e "${YELLOW}Removing old volumes...${NC}"
# docker-compose -f docker-compose.db.yml down -v

# Create necessary directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p backups
mkdir -p logs/postgresql
mkdir -p logs/redis

# Start the databases
echo -e "${YELLOW}Starting database services...${NC}"
docker-compose -f docker-compose.db.yml up -d

# Wait for services to be healthy
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 5

# Check PostgreSQL
echo -n "PostgreSQL: "
for i in {1..30}; do
    if docker-compose -f docker-compose.db.yml exec -T postgresql pg_isready -U postgres -d ytempire_dev &> /dev/null; then
        echo -e "${GREEN}Ready${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

# Check Redis
echo -n "Redis: "
for i in {1..30}; do
    if docker-compose -f docker-compose.db.yml exec -T redis redis-cli ping &> /dev/null; then
        echo -e "${GREEN}Ready${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

# Show service status
echo -e "\n${GREEN}Service Status:${NC}"
docker-compose -f docker-compose.db.yml ps

# Display connection information
echo -e "\n${GREEN}Database Connection Information:${NC}"
echo "================================"
echo -e "${YELLOW}PostgreSQL:${NC}"
echo "  Host: localhost"
echo "  Port: 5432"
echo "  Database: ytempire_dev"
echo "  User: ytempire_user"
echo "  Password: ytempire_pass"
echo "  URL: postgresql://ytempire_user:ytempire_pass@localhost:5432/ytempire_dev"

echo -e "\n${YELLOW}Redis:${NC}"
echo "  Host: localhost"
echo "  Port: 6379"
echo "  URL: redis://localhost:6379/0"

echo -e "\n${YELLOW}Web Interfaces:${NC}"
echo "  pgAdmin: http://localhost:8080"
echo "    Email: admin@ytempire.com"
echo "    Password: admin123"
echo "  Redis Commander: http://localhost:8081"
echo "    Username: admin"
echo "    Password: admin123"

echo -e "\n${YELLOW}Test Connection:${NC}"
echo "  PostgreSQL: psql postgresql://ytempire_user:ytempire_pass@localhost:5432/ytempire_dev -c 'SELECT current_database();'"
echo "  Redis: redis-cli -h localhost -p 6379 ping"

echo -e "\n${GREEN}Setup complete!${NC}"
echo "To stop the databases: docker-compose -f docker-compose.db.yml down"
echo "To view logs: docker-compose -f docker-compose.db.yml logs -f"