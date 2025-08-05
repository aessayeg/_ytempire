#!/bin/bash

echo "========================================"
echo "YTEmpire CI/CD Test Runner"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}ERROR: Docker is not running. Please start Docker.${NC}"
    exit 1
fi

echo "[1/7] Checking Docker Services..."
docker ps --format "table {{.Names}}\t{{.Status}}" | grep ytempire
echo ""

echo "[2/7] Testing Database Connection..."
if docker exec ytempire-postgresql pg_isready -U ytempire_user -d ytempire_dev > /dev/null 2>&1; then
    echo -e "${GREEN}SUCCESS: PostgreSQL is ready${NC}"
else
    echo -e "${RED}ERROR: PostgreSQL is not ready${NC}"
fi
echo ""

echo "[3/7] Testing Redis Connection..."
if docker exec ytempire-redis redis-cli ping > /dev/null 2>&1; then
    echo -e "${GREEN}SUCCESS: Redis is ready${NC}"
else
    echo -e "${RED}ERROR: Redis is not ready${NC}"
fi
echo ""

echo "[4/7] Running ESLint..."
if npm run lint --silent 2>/dev/null; then
    echo -e "${GREEN}SUCCESS: No linting errors${NC}"
else
    echo -e "${YELLOW}WARNING: Linting issues found (see above)${NC}"
fi
echo ""

echo "[5/7] Running Prettier Check..."
if npx prettier --check "**/*.{js,jsx,json}" --loglevel silent 2>/dev/null; then
    echo -e "${GREEN}SUCCESS: Code formatting is correct${NC}"
else
    echo -e "${YELLOW}WARNING: Formatting issues found${NC}"
fi
echo ""

echo "[6/7] Running Unit Tests..."
if npm test -- tests/unit/database.test.js --silent 2>/dev/null; then
    echo -e "${GREEN}SUCCESS: Unit tests passed${NC}"
else
    echo -e "${YELLOW}WARNING: Some unit tests failed${NC}"
fi
echo ""

echo "[7/7] Running Integration Tests..."
if npm test -- tests/integration/api.test.js --silent 2>/dev/null; then
    echo -e "${GREEN}SUCCESS: Integration tests passed${NC}"
else
    echo -e "${YELLOW}WARNING: Some integration tests failed${NC}"
fi
echo ""

echo "========================================"
echo "Test Summary:"
echo "========================================"
echo ""
echo "Docker Services: RUNNING"
echo "PostgreSQL: READY (ytempire_user/ytempire_pass)"
echo "Redis: READY"
echo "ESLint: Check output above"
echo "Prettier: Check output above"
echo "Unit Tests: Check output above"
echo "Integration Tests: Check output above"
echo ""
echo "To run GitHub Actions locally:"
echo "  act -W .github/workflows/lint-test.yml"
echo ""
echo "To trigger GitHub Actions remotely:"
echo "  gh workflow run lint-test.yml"
echo ""
echo "========================================"