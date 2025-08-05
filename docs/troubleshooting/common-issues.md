# Common Issues & Troubleshooting Guide

This guide covers the most common issues encountered when setting up and running YTEmpire, with step-by-step solutions.

## Table of Contents
- [Docker Issues](#docker-issues)
- [Database Issues](#database-issues)
- [Service Connection Issues](#service-connection-issues)
- [Frontend Issues](#frontend-issues)
- [Backend API Issues](#backend-api-issues)
- [Performance Issues](#performance-issues)
- [Development Environment Issues](#development-environment-issues)
- [Quick Diagnostic Commands](#quick-diagnostic-commands)

## Docker Issues

### Issue: Docker Daemon Not Running

**Symptoms:**
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Solutions:**

**macOS/Windows:**
1. Open Docker Desktop application
2. Wait for Docker to start (whale icon in system tray)
3. Verify: `docker version`

**Linux:**
```bash
# Start Docker service
sudo systemctl start docker

# Enable Docker to start on boot
sudo systemctl enable docker

# Verify Docker is running
sudo systemctl status docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Issue: Port Already in Use

**Symptoms:**
```
Error: bind: address already in use
```

**Solutions:**

```bash
# Find what's using the port (example for port 5432)
# macOS/Linux
lsof -i :5432

# Windows
netstat -ano | findstr :5432

# Kill the process
kill -9 <PID>

# Or stop all YTEmpire services
docker-compose down

# Force remove containers
docker-compose down --volumes --remove-orphans
```

### Issue: Out of Disk Space

**Symptoms:**
```
No space left on device
```

**Solutions:**

```bash
# Check disk usage
df -h

# Clean up Docker
docker system prune -a --volumes

# Remove old images
docker image prune -a

# Remove stopped containers
docker container prune

# Remove unused volumes
docker volume prune

# Check Docker disk usage
docker system df
```

### Issue: Permission Denied

**Symptoms:**
```
permission denied while trying to connect to the Docker daemon socket
```

**Solutions:**

```bash
# Linux: Fix Docker socket permissions
sudo chmod 666 /var/run/docker.sock

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Fix script permissions
chmod +x scripts/*.sh
```

## Database Issues

### Issue: PostgreSQL Connection Failed

**Symptoms:**
```
FATAL: password authentication failed for user "ytempire_user"
could not connect to server: Connection refused
```

**Solutions:**

```bash
# Check if PostgreSQL is running
docker-compose ps postgresql

# Check PostgreSQL logs
docker logs ytempire-postgresql

# Restart PostgreSQL
docker-compose restart postgresql

# Reset database completely
docker-compose down -v
docker volume rm ytempire_postgres_data
docker-compose up -d postgresql

# Test connection
docker exec ytempire-postgresql psql -U ytempire_user -d ytempire_dev -c "SELECT 1"
```

### Issue: Database Migrations Failed

**Symptoms:**
```
Error: relation "users.accounts" does not exist
```

**Solutions:**

```bash
# Run migrations manually
docker exec ytempire-postgresql psql -U ytempire_user -d ytempire_dev -f /docker-entrypoint-initdb.d/00-init-all.sql

# Check migration status
docker exec ytempire-postgresql psql -U ytempire_user -d ytempire_dev -c "\dt *.*"

# Reset and recreate database
docker-compose down -v
docker-compose up -d postgresql
docker-compose exec postgresql psql -U ytempire_user -d ytempire_dev < database/init/00-init-all.sql
```

### Issue: pgAdmin Cannot Connect

**Symptoms:**
```
Unable to connect to server: timeout expired
```

**Solutions:**

```bash
# Ensure pgAdmin is running
docker-compose ps pgadmin

# Restart pgAdmin
docker-compose restart pgadmin

# Check pgAdmin configuration
cat pgadmin/servers.json

# Access pgAdmin
# URL: http://localhost:8080
# Email: admin@example.com
# Password: admin

# In pgAdmin, use these connection details:
# Host: postgresql (not localhost)
# Port: 5432
# Username: ytempire_user
# Password: (from .env file)
```

## Service Connection Issues

### Issue: Backend Cannot Connect to Database

**Symptoms:**
```
Error: connect ECONNREFUSED 127.0.0.1:5432
```

**Solutions:**

```bash
# Check environment variables
docker-compose exec backend env | grep POSTGRES

# Ensure services are on same network
docker network ls
docker network inspect ytempire_ytempire-network

# Update database URL in .env
# Use service name, not localhost:
DATABASE_URL=postgresql://ytempire_user:password@postgresql:5432/ytempire_dev

# Restart backend
docker-compose restart backend
```

### Issue: Redis Connection Failed

**Symptoms:**
```
Error: Redis connection to redis:6379 failed
```

**Solutions:**

```bash
# Check Redis is running
docker-compose ps redis

# Test Redis connection
docker exec ytempire-redis redis-cli ping

# Check Redis logs
docker logs ytempire-redis

# Restart Redis
docker-compose restart redis

# Clear Redis data if corrupted
docker exec ytempire-redis redis-cli FLUSHALL
```

## Frontend Issues

### Issue: Frontend Shows 404 Error

**Symptoms:**
- Blank page or 404 error when accessing http://localhost:3000

**Solutions:**

```bash
# Check frontend logs
docker logs ytempire-frontend

# Rebuild frontend
docker-compose build --no-cache frontend
docker-compose up -d frontend

# Check if Next.js is building
docker exec ytempire-frontend npm run build

# Clear Next.js cache
docker exec ytempire-frontend rm -rf .next
docker-compose restart frontend
```

### Issue: Hot Reload Not Working

**Symptoms:**
- Changes not reflected without manual refresh

**Solutions:**

```bash
# Check volume mounts
docker-compose config | grep -A 5 frontend

# Ensure WATCHPACK_POLLING is set for Windows
# Add to docker-compose.yml under frontend environment:
WATCHPACK_POLLING=true
CHOKIDAR_USEPOLLING=true

# Restart frontend
docker-compose restart frontend
```

## Backend API Issues

### Issue: API Returns 500 Error

**Symptoms:**
```
Internal Server Error
```

**Solutions:**

```bash
# Check backend logs
docker logs ytempire-backend --tail=100

# Check environment variables
docker-compose exec backend env

# Test database connection from backend
docker-compose exec backend npm run db:test

# Restart backend with debug logging
docker-compose exec backend npm run dev:debug
```

### Issue: CORS Errors

**Symptoms:**
```
Access to XMLHttpRequest blocked by CORS policy
```

**Solutions:**

```javascript
// Check backend CORS configuration
// In backend/src/app.js or server.js
app.use(cors({
  origin: process.env.CLIENT_URL || 'http://localhost:3000',
  credentials: true
}));
```

```bash
# Update .env file
CLIENT_URL=http://localhost:3000

# Restart backend
docker-compose restart backend
```

## Performance Issues

### Issue: Slow Database Queries

**Symptoms:**
- API responses taking >1 second

**Solutions:**

```bash
# Check slow queries
docker exec ytempire-postgresql psql -U ytempire_user -d ytempire_dev -c "
SELECT query, mean_exec_time, calls 
FROM pg_stat_statements 
ORDER BY mean_exec_time DESC 
LIMIT 10;"

# Add missing indexes
docker exec ytempire-postgresql psql -U ytempire_user -d ytempire_dev -f database/init/08-indexes-performance.sql

# Analyze tables
docker exec ytempire-postgresql psql -U ytempire_user -d ytempire_dev -c "ANALYZE;"

# Check table sizes
docker exec ytempire-postgresql psql -U ytempire_user -d ytempire_dev -c "
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;"
```

### Issue: High Memory Usage

**Symptoms:**
- Docker using >8GB RAM

**Solutions:**

```bash
# Check memory usage by container
docker stats --no-stream

# Limit container memory in docker-compose.yml
services:
  postgresql:
    mem_limit: 1g
  backend:
    mem_limit: 512m

# Restart services
docker-compose down
docker-compose up -d
```

## Development Environment Issues

### Issue: VS Code Debugging Not Working

**Symptoms:**
- Breakpoints not hitting

**Solutions:**

```bash
# Check launch.json configuration
cat .vscode/launch.json

# Ensure debugger port is exposed
# In docker-compose.yml:
backend:
  ports:
    - "9229:9229"
  command: node --inspect=0.0.0.0:9229 server.js

# Restart backend in debug mode
docker-compose restart backend
```

### Issue: Environment Variables Not Loading

**Symptoms:**
- undefined environment variables

**Solutions:**

```bash
# Check .env file exists
ls -la .env

# Copy from template
cp .env.example .env

# Verify Docker Compose is reading .env
docker-compose config | grep JWT_SECRET

# Force reload
docker-compose down
docker-compose --env-file .env up -d
```

## Quick Diagnostic Commands

### System Health Check
```bash
#!/bin/bash
# save as check-health.sh

echo "🔍 YTEmpire System Diagnostics"
echo "================================"

# Docker status
echo "Docker Status:"
docker version --format 'Client: {{.Client.Version}} Server: {{.Server.Version}}'

# Service status
echo -e "\nService Status:"
docker-compose ps --services | while read service; do
  if docker-compose ps | grep -q "$service.*Up"; then
    echo "✅ $service"
  else
    echo "❌ $service"
  fi
done

# Database check
echo -e "\nDatabase Check:"
docker exec ytempire-postgresql psql -U ytempire_user -d ytempire_dev -c "SELECT COUNT(*) as tables FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog', 'information_schema');" 2>/dev/null || echo "❌ Database connection failed"

# Redis check
echo -e "\nRedis Check:"
docker exec ytempire-redis redis-cli ping 2>/dev/null || echo "❌ Redis connection failed"

# API check
echo -e "\nAPI Check:"
curl -s http://localhost:5000/health | grep -q "OK" && echo "✅ API healthy" || echo "❌ API not responding"

# Disk usage
echo -e "\nDisk Usage:"
df -h . | tail -1

# Memory usage
echo -e "\nMemory Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.MemUsage}}"
```

### Quick Reset
```bash
#!/bin/bash
# save as reset-all.sh

echo "⚠️  This will delete all data. Continue? (y/n)"
read -r response
if [[ "$response" == "y" ]]; then
  docker-compose down -v
  docker system prune -a --volumes -f
  rm -rf postgres_data redis_data pgadmin_data
  ./scripts/setup.sh
  echo "✅ Reset complete"
fi
```

## Getting Help

If these solutions don't resolve your issue:

1. **Check Logs:**
   ```bash
   docker-compose logs > debug.log
   ```

2. **Search Issues:**
   - [GitHub Issues](https://github.com/yourusername/ytempire/issues)

3. **Create Issue:**
   Include:
   - Error messages
   - `docker-compose ps` output
   - `docker-compose logs` output
   - System information

4. **Community Support:**
   - Discord: [YTEmpire Discord](https://discord.gg/ytempire)
   - Email: support@ytempire.com

---

[← Back to Documentation](../README.md) | [Performance Optimization →](performance-optimization.md)