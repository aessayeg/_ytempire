#!/bin/bash

# Docker Compose Validation Script
# YTEmpire Project

echo "======================================"
echo "YTEmpire Docker Compose Validation"
echo "======================================"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Docker
echo -e "\n${YELLOW}Checking Docker installation...${NC}"
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker is installed${NC}"
    docker --version
else
    echo -e "${RED}✗ Docker is not installed${NC}"
    exit 1
fi

# Check Docker Compose
echo -e "\n${YELLOW}Checking Docker Compose...${NC}"
if command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✓ Docker Compose is installed${NC}"
    docker-compose --version
else
    echo -e "${RED}✗ Docker Compose is not installed${NC}"
    exit 1
fi

# Validate docker-compose.yml
echo -e "\n${YELLOW}Validating docker-compose.yml...${NC}"
if docker-compose config > /dev/null 2>&1; then
    echo -e "${GREEN}✓ docker-compose.yml is valid${NC}"
else
    echo -e "${RED}✗ docker-compose.yml has errors${NC}"
    docker-compose config
    exit 1
fi

# Check required files
echo -e "\n${YELLOW}Checking required files...${NC}"
required_files=(
    "docker-compose.yml"
    "frontend/Dockerfile.dev"
    "backend/Dockerfile.dev"
    "nginx/nginx.conf"
    ".env.development"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓ $file exists${NC}"
    else
        echo -e "${RED}✗ $file is missing${NC}"
    fi
done

# Check services defined
echo -e "\n${YELLOW}Checking defined services...${NC}"
services=$(docker-compose config --services)
expected_services=("frontend" "backend" "postgresql" "redis" "nginx" "pgadmin" "mailhog")

for service in "${expected_services[@]}"; do
    if echo "$services" | grep -q "^$service$"; then
        echo -e "${GREEN}✓ $service service is defined${NC}"
    else
        echo -e "${RED}✗ $service service is missing${NC}"
    fi
done

# Check port mappings
echo -e "\n${YELLOW}Checking port mappings...${NC}"
ports=(
    "3000:3000"  # Frontend
    "5000:5000"  # Backend
    "5432:5432"  # PostgreSQL
    "6379:6379"  # Redis
    "80:80"      # Nginx HTTP
    "443:443"    # Nginx HTTPS
    "8080:80"    # pgAdmin
    "1025:1025"  # MailHog SMTP
    "8025:8025"  # MailHog UI
)

config=$(docker-compose config)
for port in "${ports[@]}"; do
    if echo "$config" | grep -q "$port"; then
        echo -e "${GREEN}✓ Port $port is mapped${NC}"
    else
        echo -e "${YELLOW}⚠ Port $port mapping not found${NC}"
    fi
done

# Summary
echo -e "\n======================================"
echo -e "${GREEN}Validation Complete!${NC}"
echo -e "======================================"
echo -e "\nTo start the services, run:"
echo -e "  ${YELLOW}docker-compose up -d${NC}"
echo -e "\nTo run tests, run:"
echo -e "  ${YELLOW}npm run test:docker${NC}"