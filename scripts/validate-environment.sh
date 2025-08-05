#!/bin/bash

# YTEmpire Environment Validation Script
# This script validates that all components of the YTEmpire development environment are properly configured and running

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REQUIRED_PORTS=(3000 5000 5432 6379 80 8080)
REQUIRED_SERVICES=("postgresql" "redis" "backend" "frontend" "nginx" "pgadmin" "mailhog")
MIN_DOCKER_VERSION="20.10"
MIN_COMPOSE_VERSION="2.0"

# Helper functions
print_header() {
    echo -e "\n${BLUE}=================================================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}=================================================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

check_command() {
    if command -v $1 &> /dev/null; then
        return 0
    else
        return 1
    fi
}

version_ge() {
    # Check if version $1 is greater than or equal to version $2
    [ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

# Start validation
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                     YTEmpire Environment Validation                          ║"
echo "║                          $(date +'%Y-%m-%d %H:%M:%S')                            ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

ERRORS=0
WARNINGS=0

# 1. Check prerequisites
print_header "1. Checking Prerequisites"

# Check Docker
echo "Checking Docker..."
if check_command docker; then
    DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "0.0")
    if version_ge "$DOCKER_VERSION" "$MIN_DOCKER_VERSION"; then
        print_success "Docker version $DOCKER_VERSION (minimum: $MIN_DOCKER_VERSION)"
    else
        print_error "Docker version $DOCKER_VERSION is below minimum required version $MIN_DOCKER_VERSION"
        ((ERRORS++))
    fi
else
    print_error "Docker is not installed"
    ((ERRORS++))
fi

# Check Docker Compose
echo -e "\nChecking Docker Compose..."
if check_command docker-compose; then
    COMPOSE_VERSION=$(docker-compose version --short 2>/dev/null || echo "0.0")
    if version_ge "$COMPOSE_VERSION" "$MIN_COMPOSE_VERSION"; then
        print_success "Docker Compose version $COMPOSE_VERSION (minimum: $MIN_COMPOSE_VERSION)"
    else
        print_warning "Docker Compose version $COMPOSE_VERSION (recommended: $MIN_COMPOSE_VERSION+)"
        ((WARNINGS++))
    fi
else
    print_error "Docker Compose is not installed"
    ((ERRORS++))
fi

# Check Git
echo -e "\nChecking Git..."
if check_command git; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    print_success "Git version $GIT_VERSION"
else
    print_error "Git is not installed"
    ((ERRORS++))
fi

# 2. Check system resources
print_header "2. Checking System Resources"

# Check available memory
echo "Checking available memory..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    TOTAL_MEM=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
else
    TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
fi

if [ "$TOTAL_MEM" -ge 8 ]; then
    print_success "Available RAM: ${TOTAL_MEM}GB (minimum: 8GB)"
else
    print_warning "Available RAM: ${TOTAL_MEM}GB (recommended: 8GB+)"
    ((WARNINGS++))
fi

# Check disk space
echo -e "\nChecking disk space..."
DISK_AVAILABLE=$(df -BG . | awk 'NR==2 {print int($4)}')
if [ "$DISK_AVAILABLE" -ge 20 ]; then
    print_success "Available disk space: ${DISK_AVAILABLE}GB (minimum: 20GB)"
else
    print_error "Insufficient disk space: ${DISK_AVAILABLE}GB (minimum: 20GB)"
    ((ERRORS++))
fi

# 3. Check port availability
print_header "3. Checking Port Availability"

for port in "${REQUIRED_PORTS[@]}"; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        SERVICE=$(lsof -Pi :$port -sTCP:LISTEN | awk 'NR==2 {print $1}')
        if [[ "$SERVICE" == *"docker"* ]] || [[ "$SERVICE" == *"com.docke"* ]]; then
            print_success "Port $port is used by Docker"
        else
            print_warning "Port $port is in use by: $SERVICE"
            ((WARNINGS++))
        fi
    else
        print_success "Port $port is available"
    fi
done

# 4. Check Docker services
print_header "4. Checking Docker Services"

echo "Checking Docker daemon..."
if docker info &>/dev/null; then
    print_success "Docker daemon is running"
else
    print_error "Docker daemon is not running"
    ((ERRORS++))
    echo "Skipping service checks..."
fi

if [ $ERRORS -eq 0 ]; then
    echo -e "\nChecking YTEmpire services..."
    for service in "${REQUIRED_SERVICES[@]}"; do
        if docker-compose ps 2>/dev/null | grep -q "ytempire-$service.*Up\|ytempire-$service.*running"; then
            print_success "Service '$service' is running"
        else
            print_warning "Service '$service' is not running"
            ((WARNINGS++))
        fi
    done
fi

# 5. Check database connectivity
print_header "5. Checking Database Connectivity"

if docker-compose ps 2>/dev/null | grep -q "ytempire-postgresql.*Up\|ytempire-postgresql.*running"; then
    echo "Testing PostgreSQL connection..."
    if docker exec ytempire-postgresql psql -U ytempire_user -d ytempire_dev -c "SELECT 1" &>/dev/null; then
        print_success "PostgreSQL connection successful"
        
        # Check schemas
        echo -e "\nChecking database schemas..."
        SCHEMAS=$(docker exec ytempire-postgresql psql -U ytempire_user -d ytempire_dev -t -c "SELECT string_agg(schema_name, ', ') FROM information_schema.schemata WHERE schema_name IN ('users', 'content', 'analytics', 'campaigns', 'system')" 2>/dev/null)
        if [ -n "$SCHEMAS" ]; then
            print_success "Database schemas found: $SCHEMAS"
        else
            print_warning "Database schemas not found - may need initialization"
            ((WARNINGS++))
        fi
    else
        print_error "PostgreSQL connection failed"
        ((ERRORS++))
    fi
else
    print_warning "PostgreSQL service not running - skipping database checks"
    ((WARNINGS++))
fi

# 6. Check Redis connectivity
print_header "6. Checking Redis Connectivity"

if docker-compose ps 2>/dev/null | grep -q "ytempire-redis.*Up\|ytempire-redis.*running"; then
    echo "Testing Redis connection..."
    if docker exec ytempire-redis redis-cli ping 2>/dev/null | grep -q PONG; then
        print_success "Redis connection successful"
        
        # Check Redis memory
        REDIS_MEM=$(docker exec ytempire-redis redis-cli INFO memory 2>/dev/null | grep used_memory_human | cut -d: -f2 | tr -d '\r')
        if [ -n "$REDIS_MEM" ]; then
            print_success "Redis memory usage: $REDIS_MEM"
        fi
    else
        print_error "Redis connection failed"
        ((ERRORS++))
    fi
else
    print_warning "Redis service not running - skipping Redis checks"
    ((WARNINGS++))
fi

# 7. Check API endpoints
print_header "7. Checking API Endpoints"

echo "Testing backend API health..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health 2>/dev/null | grep -q "200"; then
    print_success "Backend API is healthy (http://localhost:5000)"
else
    print_warning "Backend API is not responding"
    ((WARNINGS++))
fi

echo -e "\nTesting frontend..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null)
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "404" ]; then
    print_success "Frontend is accessible (http://localhost:3000)"
else
    print_warning "Frontend is not accessible (HTTP $HTTP_CODE)"
    ((WARNINGS++))
fi

echo -e "\nTesting Nginx proxy..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null | grep -q "200\|404"; then
    print_success "Nginx proxy is working (http://localhost)"
else
    print_warning "Nginx proxy is not responding"
    ((WARNINGS++))
fi

# 8. Check environment configuration
print_header "8. Checking Environment Configuration"

echo "Checking .env file..."
if [ -f .env ]; then
    print_success ".env file exists"
    
    # Check for required variables
    REQUIRED_VARS=("POSTGRES_USER" "POSTGRES_PASSWORD" "POSTGRES_DB" "JWT_SECRET")
    for var in "${REQUIRED_VARS[@]}"; do
        if grep -q "^$var=" .env; then
            print_success "Environment variable $var is set"
        else
            print_error "Environment variable $var is missing"
            ((ERRORS++))
        fi
    done
else
    print_error ".env file not found"
    ((ERRORS++))
fi

# 9. Check VS Code configuration
print_header "9. Checking VS Code Configuration"

echo "Checking VS Code settings..."
if [ -d .vscode ]; then
    print_success ".vscode directory exists"
    
    VS_FILES=("settings.json" "launch.json" "tasks.json" "extensions.json")
    for file in "${VS_FILES[@]}"; do
        if [ -f ".vscode/$file" ]; then
            print_success "VS Code $file found"
        else
            print_warning "VS Code $file not found"
            ((WARNINGS++))
        fi
    done
else
    print_warning ".vscode directory not found"
    ((WARNINGS++))
fi

# 10. Summary
print_header "Validation Summary"

TOTAL_CHECKS=$((ERRORS + WARNINGS))

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                            🎉 PERFECT SETUP! 🎉                              ║${NC}"
    echo -e "${GREEN}║                All checks passed without any issues!                         ║${NC}"
    echo -e "${GREEN}║                Your YTEmpire environment is ready for development.           ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                        ✅ SETUP FUNCTIONAL                                   ║${NC}"
    echo -e "${YELLOW}║           Found $WARNINGS warning(s) but no critical errors.                 ║${NC}"
    echo -e "${YELLOW}║           Your environment should work but consider addressing warnings.     ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
else
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                         ❌ SETUP INCOMPLETE                                  ║${NC}"
    echo -e "${RED}║               Found $ERRORS error(s) and $WARNINGS warning(s).               ║${NC}"
    echo -e "${RED}║               Please fix the errors before proceeding.                       ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
fi

echo -e "\n${BLUE}Quick Links:${NC}"
echo "  Frontend:    http://localhost:3000"
echo "  Backend API: http://localhost:5000"
echo "  pgAdmin:     http://localhost:8080 (admin@example.com / admin)"
echo "  MailHog:     http://localhost:8025"

echo -e "\n${BLUE}Next Steps:${NC}"
if [ $ERRORS -gt 0 ]; then
    echo "  1. Fix the errors listed above"
    echo "  2. Run: docker-compose up -d"
    echo "  3. Run this validation script again"
else
    echo "  1. Start developing: code ."
    echo "  2. View logs: docker-compose logs -f"
    echo "  3. Run tests: npm test"
fi

# Exit with appropriate code
if [ $ERRORS -gt 0 ]; then
    exit 1
else
    exit 0
fi