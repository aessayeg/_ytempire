# Environment Setup Guide

Complete step-by-step guide to setting up the YTEmpire development environment.

## Table of Contents
- [Quick Setup](#quick-setup)
- [Repository Setup](#repository-setup)
- [Docker Environment](#docker-environment)
- [Service Configuration](#service-configuration)
- [Environment Variables](#environment-variables)
- [Service Startup](#service-startup)
- [Validation](#validation)
- [Troubleshooting](#troubleshooting)

## Quick Setup

For experienced developers who want to get started immediately:

```bash
# Clone and setup
git clone https://github.com/yourusername/ytempire.git
cd ytempire
cp .env.example .env
./scripts/setup.sh

# Start services
docker-compose up -d

# Validate
curl http://localhost:5000/health
```

## Repository Setup

### 1. Clone the Repository

#### Using SSH (Recommended)
```bash
git clone git@github.com:yourusername/ytempire.git
cd ytempire
```

#### Using HTTPS
```bash
git clone https://github.com/yourusername/ytempire.git
cd ytempire
```

### 2. Verify Repository Structure
```bash
# Check directory structure
ls -la

# Expected directories:
# backend/     - Backend API service
# frontend/    - React frontend application
# database/    - Database schemas and migrations
# scripts/     - Utility scripts
# docs/        - Documentation
# .vscode/     - VS Code configuration
```

### 3. Set File Permissions
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Set proper permissions for database init scripts
chmod 755 database/init/*.sql
chmod 755 database/init/*.sh

# Create required directories
mkdir -p uploads temp logs backups pgadmin
```

## Docker Environment

### 1. Docker Compose Configuration

YTEmpire uses multiple Docker Compose files:

- `docker-compose.yml` - Core services
- `docker-compose.override.yml` - Development overrides
- `docker-compose.prod.yml` - Production configuration

#### Review Main Configuration
```yaml
# docker-compose.yml structure
services:
  frontend:     # React application
  backend:      # Node.js API
  postgresql:   # Database
  redis:        # Cache
  nginx:        # Reverse proxy
  pgadmin:      # Database admin
  mailhog:      # Email testing
```

### 2. Docker Network Configuration

```bash
# Create custom network (if not using default)
docker network create ytempire-network --subnet=172.20.0.0/16

# Verify network
docker network ls
docker network inspect ytempire-network
```

### 3. Volume Management

```bash
# Create named volumes
docker volume create postgres_data
docker volume create redis_data
docker volume create pgadmin_data

# List volumes
docker volume ls

# Inspect volume
docker volume inspect postgres_data
```

## Service Configuration

### 1. PostgreSQL Configuration

#### Custom PostgreSQL Configuration
Create `database/postgresql.conf`:
```conf
# Performance Tuning
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1

# Connections
max_connections = 100
```

#### Initialize Database
```bash
# Database will auto-initialize on first run
# Manual initialization (if needed)
docker-compose up -d postgresql
docker exec ytempire-postgresql psql -U ytempire_user -d ytempire_dev -f /docker-entrypoint-initdb.d/00-init-all.sql
```

### 2. Redis Configuration

#### Custom Redis Configuration
Edit `redis/redis.conf`:
```conf
# Memory Management
maxmemory 256mb
maxmemory-policy allkeys-lru

# Persistence
save 900 1
save 300 10
save 60 10000
appendonly yes
appendfsync everysec

# Performance
tcp-keepalive 60
timeout 300
```

### 3. Nginx Configuration

The Nginx configuration is located in `nginx/nginx.conf`:
```nginx
upstream frontend {
    server frontend:3000;
}

upstream backend {
    server backend:5000;
}

server {
    listen 80;
    server_name localhost ytempire.local;

    location / {
        proxy_pass http://frontend;
    }

    location /api {
        proxy_pass http://backend;
    }
}
```

## Environment Variables

### 1. Create Environment File

```bash
# Copy template
cp .env.example .env

# Or create from scratch
cat > .env << 'EOF'
# Application
NODE_ENV=development
APP_NAME=YTEmpire
APP_URL=http://localhost:3000
API_URL=http://localhost:5000

# Database
POSTGRES_HOST=postgresql
POSTGRES_PORT=5432
POSTGRES_USER=ytempire_user
POSTGRES_PASSWORD=SecurePassword123!
POSTGRES_DB=ytempire_dev
DATABASE_URL=postgresql://ytempire_user:SecurePassword123!@postgresql:5432/ytempire_dev

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_URL=redis://redis:6379

# Authentication
JWT_SECRET=your-super-secret-jwt-key-change-this
JWT_EXPIRATION=7d
SESSION_SECRET=your-session-secret-key-change-this

# YouTube API
YOUTUBE_API_KEY=your-youtube-api-key
YOUTUBE_CLIENT_ID=your-oauth-client-id
YOUTUBE_CLIENT_SECRET=your-oauth-client-secret
YOUTUBE_REDIRECT_URI=http://localhost:5000/auth/youtube/callback

# Email (MailHog for development)
SMTP_HOST=mailhog
SMTP_PORT=1025
SMTP_SECURE=false
SMTP_USER=
SMTP_PASS=
EMAIL_FROM=noreply@ytempire.local

# Frontend
NEXT_PUBLIC_API_URL=http://localhost:5000
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_WS_URL=ws://localhost:5000

# Monitoring
SENTRY_DSN=
LOG_LEVEL=debug

# Storage
UPLOAD_PATH=/app/uploads
TEMP_PATH=/app/temp
MAX_FILE_SIZE=104857600
EOF
```

### 2. Validate Environment Variables

```bash
# Check .env file
cat .env | grep -E "^[^#]" | wc -l
# Should show ~25-30 variables

# Verify no sensitive data in git
git status .env
# Should show .env is ignored
```

### 3. Service-Specific Environment Files

Create additional environment files if needed:
- `.env.frontend` - Frontend-specific variables
- `.env.backend` - Backend-specific variables
- `.env.test` - Testing environment

## Service Startup

### 1. Initial Setup Script

Run the automated setup script:
```bash
./scripts/setup.sh
```

This script will:
- Check prerequisites
- Create necessary directories
- Initialize database
- Install dependencies
- Configure services

### 2. Manual Service Startup

If you prefer manual control:

```bash
# Start core infrastructure first
docker-compose up -d postgresql redis

# Wait for database to be ready
sleep 10

# Start application services
docker-compose up -d backend frontend

# Start supporting services
docker-compose up -d nginx pgadmin mailhog

# View all services
docker-compose ps
```

### 3. Service Health Checks

```bash
# Check PostgreSQL
docker exec ytempire-postgresql pg_isready -U ytempire_user

# Check Redis
docker exec ytempire-redis redis-cli ping

# Check Backend API
curl http://localhost:5000/health

# Check Frontend
curl -I http://localhost:3000

# Check Nginx
curl -I http://localhost
```

## Validation

### 1. Automated Validation Script

Create `scripts/validate-environment.sh`:
```bash
#!/bin/bash

echo "🔍 Validating YTEmpire Environment..."

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check Docker services
echo "Checking Docker services..."
services=("postgresql" "redis" "backend" "frontend" "nginx")
for service in "${services[@]}"; do
    if docker-compose ps | grep -q "ytempire-$service.*Up"; then
        echo -e "${GREEN}✅ $service is running${NC}"
    else
        echo -e "${RED}❌ $service is not running${NC}"
        exit 1
    fi
done

# Check database connection
echo "Checking database connection..."
if docker exec ytempire-postgresql psql -U ytempire_user -d ytempire_dev -c "SELECT 1" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Database connection successful${NC}"
else
    echo -e "${RED}❌ Database connection failed${NC}"
    exit 1
fi

# Check Redis connection
echo "Checking Redis connection..."
if docker exec ytempire-redis redis-cli ping | grep -q PONG; then
    echo -e "${GREEN}✅ Redis connection successful${NC}"
else
    echo -e "${RED}❌ Redis connection failed${NC}"
    exit 1
fi

# Check API endpoints
echo "Checking API endpoints..."
if curl -s http://localhost:5000/health | grep -q "OK"; then
    echo -e "${GREEN}✅ Backend API is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  Backend API health check failed${NC}"
fi

# Check frontend
echo "Checking frontend..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200\|404"; then
    echo -e "${GREEN}✅ Frontend is accessible${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend not accessible${NC}"
fi

# Check pgAdmin
echo "Checking pgAdmin..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|302"; then
    echo -e "${GREEN}✅ pgAdmin is accessible${NC}"
else
    echo -e "${YELLOW}⚠️  pgAdmin not accessible${NC}"
fi

echo -e "${GREEN}✅ Environment validation complete!${NC}"
```

### 2. Database Validation

```bash
# Check schemas
docker exec ytempire-postgresql psql -U ytempire_user -d ytempire_dev -c "\dn"

# Check tables
docker exec ytempire-postgresql psql -U ytempire_user -d ytempire_dev -c "\dt users.*"
docker exec ytempire-postgresql psql -U ytempire_user -d ytempire_dev -c "\dt content.*"
docker exec ytempire-postgresql psql -U ytempire_user -d ytempire_dev -c "\dt analytics.*"

# Test query
docker exec ytempire-postgresql psql -U ytempire_user -d ytempire_dev -c "SELECT COUNT(*) FROM users.accounts"
```

### 3. Service Logs Review

```bash
# View all logs
docker-compose logs

# View specific service logs
docker-compose logs postgresql
docker-compose logs backend
docker-compose logs frontend

# Follow logs in real-time
docker-compose logs -f --tail=100
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Port Already in Use
```bash
# Find process using port
lsof -i :5000
# Kill process
kill -9 <PID>

# Or change port in docker-compose.yml
```

#### 2. Database Connection Failed
```bash
# Check PostgreSQL logs
docker logs ytempire-postgresql

# Restart PostgreSQL
docker-compose restart postgresql

# Reset database
docker-compose down -v
docker-compose up -d postgresql
```

#### 3. Frontend Build Errors
```bash
# Rebuild frontend
docker-compose build --no-cache frontend
docker-compose up -d frontend

# Check logs
docker logs ytempire-frontend
```

#### 4. Permission Denied Errors
```bash
# Fix script permissions
chmod +x scripts/*.sh

# Fix Docker socket permissions (Linux)
sudo chmod 666 /var/run/docker.sock
```

#### 5. Out of Disk Space
```bash
# Clean up Docker
docker system prune -a --volumes

# Remove unused images
docker image prune -a

# Clear logs
truncate -s 0 $(docker inspect --format='{{.LogPath}}' ytempire-backend)
```

### Reset Everything
If you need to start fresh:

```bash
# Stop and remove everything
docker-compose down -v
docker system prune -a --volumes

# Remove local data
rm -rf postgres_data redis_data pgadmin_data

# Start fresh
./scripts/setup.sh
```

## Next Steps

After successful environment setup:

1. [Configure VS Code](vscode-setup.md) for development
2. [Set up the database](database-setup.md) with migrations
3. [Run tests](testing-setup.md) to verify everything works
4. Start developing!

## Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [YTEmpire Architecture](../architecture/system-overview.md)

---

[← Prerequisites](prerequisites.md) | [Next: Database Setup →](database-setup.md)