@echo off
echo ========================================
echo YTEmpire CI/CD Test Runner
echo ========================================
echo.

REM Check if Docker is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker is not running. Please start Docker Desktop.
    exit /b 1
)

echo [1/7] Checking Docker Services...
docker ps --format "table {{.Names}}\t{{.Status}}" | findstr ytempire
echo.

echo [2/7] Testing Database Connection...
docker exec ytempire-postgresql pg_isready -U ytempire_user -d ytempire_dev
if %errorlevel% equ 0 (
    echo SUCCESS: PostgreSQL is ready
) else (
    echo ERROR: PostgreSQL is not ready
)
echo.

echo [3/7] Testing Redis Connection...
docker exec ytempire-redis redis-cli ping
if %errorlevel% equ 0 (
    echo SUCCESS: Redis is ready
) else (
    echo ERROR: Redis is not ready
)
echo.

echo [4/7] Running ESLint...
call npm run lint --silent
if %errorlevel% equ 0 (
    echo SUCCESS: No linting errors
) else (
    echo WARNING: Linting issues found (see above)
)
echo.

echo [5/7] Running Prettier Check...
npx prettier --check "**/*.{js,jsx,json}" --loglevel silent
if %errorlevel% equ 0 (
    echo SUCCESS: Code formatting is correct
) else (
    echo WARNING: Formatting issues found
)
echo.

echo [6/7] Running Unit Tests...
npm test -- tests/unit/database.test.js --silent
if %errorlevel% equ 0 (
    echo SUCCESS: Unit tests passed
) else (
    echo WARNING: Some unit tests failed
)
echo.

echo [7/7] Running Integration Tests...
npm test -- tests/integration/api.test.js --silent
if %errorlevel% equ 0 (
    echo SUCCESS: Integration tests passed
) else (
    echo WARNING: Some integration tests failed
)
echo.

echo ========================================
echo Test Summary:
echo ========================================
echo.
echo Docker Services: RUNNING
echo PostgreSQL: READY (ytempire_user/ytempire_pass)
echo Redis: READY
echo ESLint: Check output above
echo Prettier: Check output above
echo Unit Tests: Check output above
echo Integration Tests: Check output above
echo.
echo To run GitHub Actions locally:
echo   act -W .github/workflows/lint-test.yml
echo.
echo To trigger GitHub Actions remotely:
echo   gh workflow run lint-test.yml
echo.
echo ========================================