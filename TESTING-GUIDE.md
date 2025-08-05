# YTEmpire CI/CD Testing Guide

## Quick Start Testing Commands

### 1. Test the Complete CI/CD Setup Locally

```bash
# Install all dependencies first
npm install
npm install --save-dev jest babel-jest @babel/core @babel/preset-env @babel/preset-react
npm install --save-dev eslint prettier eslint-plugin-react eslint-plugin-react-hooks
npm install --save-dev supertest axios form-data identity-obj-proxy

# Run linting checks
npm run lint

# Run prettier formatting check
npx prettier --check .

# Run all tests with coverage
npm test -- --coverage

# Run specific test files
npm test -- tests/unit/database.test.js
npm test -- tests/integration/api.test.js
```

### 2. Test GitHub Actions Workflow Locally

```bash
# Install act (GitHub Actions local runner)
# On Windows with Chocolatey:
choco install act-cli

# On Windows with Scoop:
scoop install act

# Test the lint-test workflow
act -W .github/workflows/lint-test.yml

# Test with specific event
act push -W .github/workflows/lint-test.yml

# Test pull request event
act pull_request -W .github/workflows/lint-test.yml
```

### 3. Docker Environment Testing

```bash
# Start all services with docker-compose
docker-compose up -d

# Verify PostgreSQL is running with correct credentials
docker exec -it ytempire_postgresql psql -U ytempire_user -d ytempire_dev -c "\dt"

# Verify Redis is running
docker exec -it ytempire_redis redis-cli ping

# Run tests against Docker services
DATABASE_URL=postgresql://ytempire_user:ytempire_pass@localhost:5432/ytempire_dev npm test

# Check container logs
docker-compose logs postgresql
docker-compose logs redis
```

### 4. Test Database Connection

```bash
# Test database connection directly
node -e "
const { Client } = require('pg');
const client = new Client({
  connectionString: 'postgresql://ytempire_user:ytempire_pass@localhost:5432/ytempire_dev'
});
client.connect()
  .then(() => console.log('✅ Database connected successfully'))
  .catch(err => console.error('❌ Database connection failed:', err))
  .finally(() => client.end());
"

# Test Redis connection
node -e "
const redis = require('redis');
const client = redis.createClient({ url: 'redis://localhost:6379' });
client.connect()
  .then(() => console.log('✅ Redis connected successfully'))
  .catch(err => console.error('❌ Redis connection failed:', err))
  .finally(() => client.quit());
"
```

### 5. Run Individual Test Suites

```bash
# Unit tests only
npm test -- tests/unit --coverage

# Integration tests only
npm test -- tests/integration --coverage

# Database tests
npm test -- tests/unit/database.test.js --verbose

# API integration tests
npm test -- tests/integration/api.test.js --verbose

# Watch mode for development
npm test -- --watch

# Run tests with specific pattern
npm test -- --testNamePattern="Database Operations"
```

### 6. Test ESLint Configuration

```bash
# Check all JavaScript files
npx eslint . --ext .js,.jsx

# Check specific directory
npx eslint backend/ --ext .js

# Fix auto-fixable issues
npx eslint . --fix

# Check with specific config
npx eslint --config .eslintrc.json backend/
```

### 7. Test Prettier Configuration

```bash
# Check formatting
npx prettier --check "**/*.{js,jsx,json,md}"

# Fix formatting
npx prettier --write "**/*.{js,jsx,json,md}"

# Check specific file types
npx prettier --check "**/*.js"
```

### 8. Performance Testing

```bash
# Run performance benchmarks
npm test -- tests/performance --verbose

# Test with performance monitoring
NODE_ENV=test npm test -- --detectOpenHandles --forceExit
```

### 9. GitHub Actions Manual Trigger

```bash
# Using GitHub CLI
gh workflow run lint-test.yml

# Trigger with specific inputs
gh workflow run lint-test.yml -f test_type=all

# Run lint only
gh workflow run lint-test.yml -f test_type=lint-only

# Run unit tests only
gh workflow run lint-test.yml -f test_type=unit-only

# Run integration tests only
gh workflow run lint-test.yml -f test_type=integration-only

# Run performance tests only
gh workflow run lint-test.yml -f test_type=performance-only
```

### 10. Verify CI Pipeline on GitHub

```bash
# Check workflow status
gh run list --workflow=lint-test.yml

# View specific run details
gh run view <run-id>

# Watch a run in progress
gh run watch <run-id>

# Download artifacts from a run
gh run download <run-id>
```

## Testing Checklist

### Pre-flight Checks

- [ ] Docker is running
- [ ] PostgreSQL container is up
- [ ] Redis container is up
- [ ] Node.js 18+ installed
- [ ] All npm dependencies installed

### Local Testing

- [ ] ESLint passes without errors
- [ ] Prettier formatting is correct
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Coverage meets 85% threshold
- [ ] No security vulnerabilities (npm audit)

### CI/CD Pipeline Testing

- [ ] Workflow syntax is valid
- [ ] Workflow triggers on push to main/develop
- [ ] Workflow triggers on pull requests
- [ ] Manual workflow dispatch works
- [ ] All job steps complete successfully
- [ ] Test artifacts are uploaded

### Database Testing

- [ ] Connection with correct credentials works
- [ ] All 5 schemas are accessible
- [ ] Database queries execute < 200ms
- [ ] Redis operations execute < 10ms

## Troubleshooting Commands

```bash
# Clear Jest cache
npx jest --clearCache

# Debug Jest configuration
npx jest --showConfig

# Run tests with debugging
NODE_OPTIONS='--inspect' npm test

# Check for conflicting dependencies
npm ls jest
npm ls eslint

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install

# Check environment variables
echo $DATABASE_URL
echo $REDIS_URL
echo $NODE_ENV

# Test specific Node version
nvm use 18
npm test

# Generate coverage report
npm test -- --coverage --coverageReporters=html
open coverage/index.html
```

## Environment Variables for Testing

```bash
# Create .env.test file
cat > .env.test << EOF
NODE_ENV=test
DATABASE_URL=postgresql://ytempire_user:ytempire_pass@localhost:5432/ytempire_dev
REDIS_URL=redis://localhost:6379
JWT_SECRET=test-jwt-secret
SESSION_SECRET=test-session-secret
PORT=5000
EOF

# Load test environment
export $(cat .env.test | xargs)
npm test
```

## Continuous Monitoring

```bash
# Watch test files for changes
npm test -- --watch

# Run tests on file change with nodemon
npx nodemon --exec "npm test" --watch tests --watch src

# Monitor GitHub Actions
watch -n 10 'gh run list --workflow=lint-test.yml --limit 5'
```

## Quick Validation Script

```bash
# Create a validation script
cat > validate-ci.sh << 'EOF'
#!/bin/bash
echo "🔍 Validating CI/CD Setup..."

# Check Node version
echo "✓ Node version: $(node -v)"

# Check npm version
echo "✓ npm version: $(npm -v)"

# Check Docker
if docker info > /dev/null 2>&1; then
    echo "✓ Docker is running"
else
    echo "✗ Docker is not running"
fi

# Check PostgreSQL
if docker exec ytempire_postgresql pg_isready -U ytempire_user > /dev/null 2>&1; then
    echo "✓ PostgreSQL is ready"
else
    echo "✗ PostgreSQL is not ready"
fi

# Check Redis
if docker exec ytempire_redis redis-cli ping > /dev/null 2>&1; then
    echo "✓ Redis is ready"
else
    echo "✗ Redis is not ready"
fi

# Run linting
echo "Running ESLint..."
if npx eslint . --quiet; then
    echo "✓ ESLint passed"
else
    echo "✗ ESLint failed"
fi

# Run tests
echo "Running tests..."
if npm test -- --silent; then
    echo "✓ Tests passed"
else
    echo "✗ Tests failed"
fi

echo "🎉 Validation complete!"
EOF

chmod +x validate-ci.sh
./validate-ci.sh
```

## Expected Test Output

When everything is working correctly, you should see:

```
PASS tests/unit/database.test.js
PASS tests/integration/api.test.js
...
Test Suites: X passed, X total
Tests: Y passed, Y total
Coverage: >85% of lines covered
```

---

**Note**: Replace `<run-id>` with actual GitHub Actions run IDs when using gh CLI commands.
