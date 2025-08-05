# YTEmpire Docker MVP Setup Guide

## Overview

This guide provides instructions for setting up and running the YTEmpire MVP development environment using Docker Compose. The setup prioritizes local development with no external cloud dependencies.

## Architecture

The YTEmpire MVP consists of the following services:

- **Frontend**: React/Next.js application (Port 3000)
- **Backend**: Node.js/Express API server (Port 5000)
- **PostgreSQL**: Primary database (Port 5432)
- **Redis**: Caching and session storage (Port 6379)
- **Nginx**: Reverse proxy and load balancer (Port 80/443)
- **pgAdmin**: Database management tool (Port 8080)
- **MailHog**: Email testing service (Port 8025 for UI, 1025 for SMTP)

## Prerequisites

1. **Docker Desktop** installed and running
2. **Docker Compose** v2.0+ installed
3. **Node.js** 16+ (for running tests)
4. **Git** for version control
5. At least 4GB of free RAM
6. 10GB of free disk space

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/aessayeg/ytempire.git
cd ytempire
```

### 2. Set Up Environment Variables

```bash
# Copy the development environment file
cp .env.development .env

# Edit .env to add your API keys (optional for MVP)
# - YouTube API credentials
# - OpenAI/Claude API keys
```

### 3. Start All Services

```bash
# Start all services in detached mode
docker-compose up -d --build

# Or use the npm script
npm run docker:up
```

### 4. Verify Services

```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs -f
```

### 5. Access Applications

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:5000
- **pgAdmin**: http://localhost:8080 (admin@ytempire.local / admin)
- **MailHog**: http://localhost:8025
- **API Documentation**: http://localhost:5000/api-docs

## Development Workflow

### Starting Development

```bash
# Start all services
docker-compose up -d

# Watch logs
docker-compose logs -f backend frontend
```

### Making Code Changes

- Frontend and backend code is mounted as volumes
- Changes are automatically reflected (hot reload)
- No need to rebuild containers for code changes

### Database Operations

```bash
# Access PostgreSQL CLI
docker-compose exec postgresql psql -U ytempire_user -d ytempire_dev

# Run migrations
docker-compose exec backend npm run migrate

# Seed database
docker-compose exec backend npm run seed
```

### Testing

#### Run All Tests

```bash
npm run test:docker:all
```

#### Run Specific Test Suites

```bash
# Test Docker configuration
npm run test:docker:compose

# Test service connectivity
npm run test:docker:services

# Test integrations
npm run test:docker:integration
```

#### Automated Test Runner

```bash
node run-docker-tests.js
```

### Debugging

#### View Container Logs

```bash
# All services
docker-compose logs

# Specific service
docker-compose logs backend

# Follow logs
docker-compose logs -f frontend
```

#### Access Container Shell

```bash
# Backend container
docker-compose exec backend sh

# PostgreSQL container
docker-compose exec postgresql bash

# Redis CLI
docker-compose exec redis redis-cli
```

## File Storage

The MVP uses local file storage instead of cloud services:

- **Uploads**: `./uploads/` directory (mounted to `/app/uploads` in backend)
- **Temp Files**: `./temp/` directory (mounted to `/app/temp` in backend)
- **Max File Size**: 100MB (configurable in `.env`)

## Email Testing

MailHog captures all emails sent by the application:

1. Access MailHog UI: http://localhost:8025
2. All emails sent by the app appear here
3. No actual emails are sent externally
4. SMTP configuration: `mailhog:1025`

## Common Tasks

### Reset Database

```bash
# Stop services and remove volumes
docker-compose down -v

# Start fresh
docker-compose up -d
```

### Update Dependencies

```bash
# Backend
docker-compose exec backend npm update

# Frontend
docker-compose exec frontend npm update

# Rebuild containers
docker-compose up -d --build
```

### Performance Monitoring

```bash
# Check resource usage
docker stats

# View detailed container info
docker-compose top
```

## Troubleshooting

### Services Won't Start

```bash
# Check for port conflicts
netstat -tulpn | grep -E '(3000|5000|5432|6379|80|443|8080|8025)'

# Clean start
docker-compose down -v
docker system prune -a
docker-compose up -d --build
```

### Database Connection Issues

```bash
# Check PostgreSQL is running
docker-compose ps postgresql

# Test connection
docker-compose exec postgresql pg_isready

# View PostgreSQL logs
docker-compose logs postgresql
```

### Frontend/Backend Not Updating

```bash
# Ensure volumes are mounted correctly
docker-compose exec frontend ls -la /app
docker-compose exec backend ls -la /app

# Restart services
docker-compose restart frontend backend
```

### Out of Disk Space

```bash
# Clean up Docker resources
docker system prune -a --volumes

# Remove unused images
docker image prune -a
```

## Production Considerations

This setup is optimized for local MVP development. For production:

1. Use proper SSL certificates (not self-signed)
2. Implement proper secrets management
3. Use managed database services
4. Configure proper backup strategies
5. Implement monitoring and alerting
6. Use production-grade builds (no dev dependencies)
7. Configure proper security headers
8. Implement rate limiting and DDoS protection

## Security Notes

- Change all default passwords before deploying
- Use environment-specific `.env` files
- Never commit `.env` files to version control
- Regularly update all Docker images
- Implement proper CORS policies
- Use HTTPS in production

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [Nginx Documentation](https://nginx.org/en/docs/)

## Support

For issues or questions:

1. Check the troubleshooting section above
2. View container logs for error messages
3. Run the test suite to identify issues
4. Check GitHub issues for known problems
5. Create a new issue with detailed error information

---

**Note**: This MVP setup is designed for rapid development and testing. It includes everything needed to build and test the YTEmpire platform without external dependencies.
