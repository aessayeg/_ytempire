#!/bin/bash
# YTEmpire Database Initialization Script
# Sets up PostgreSQL and Redis for local development

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "======================================"
echo "YTEmpire Database Setup"
echo "======================================"

# Check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo "❌ Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    echo "✅ Prerequisites checked"
}

# Create necessary directories
create_directories() {
    echo "Creating data directories..."
    
    mkdir -p "$PROJECT_ROOT/data/postgresql"
    mkdir -p "$PROJECT_ROOT/data/redis"
    mkdir -p "$PROJECT_ROOT/backups"
    mkdir -p "$PROJECT_ROOT/logs/postgresql"
    mkdir -p "$PROJECT_ROOT/logs/redis"
    
    # Set proper permissions
    chmod -R 755 "$PROJECT_ROOT/data"
    chmod -R 755 "$PROJECT_ROOT/logs"
    
    echo "✅ Directories created"
}

# Generate environment file if not exists
setup_environment() {
    echo "Setting up environment..."
    
    if [ ! -f "$PROJECT_ROOT/.env" ]; then
        cp "$PROJECT_ROOT/.env.database" "$PROJECT_ROOT/.env"
        echo "✅ Environment file created from template"
    else
        echo "⚠️  Environment file already exists, skipping..."
    fi
}

# Start databases
start_databases() {
    echo "Starting database services..."
    
    cd "$PROJECT_ROOT"
    docker-compose -f docker-compose.db.yml up -d
    
    echo "⏳ Waiting for services to be healthy..."
    
    # Wait for PostgreSQL
    echo -n "Waiting for PostgreSQL..."
    for i in {1..30}; do
        if docker-compose -f docker-compose.db.yml exec -T postgresql pg_isready -U ytempire_user -d ytempire_dev &> /dev/null; then
            echo " ✅"
            break
        fi
        echo -n "."
        sleep 2
    done
    
    # Wait for Redis
    echo -n "Waiting for Redis..."
    for i in {1..30}; do
        if docker-compose -f docker-compose.db.yml exec -T redis redis-cli ping &> /dev/null; then
            echo " ✅"
            break
        fi
        echo -n "."
        sleep 2
    done
}

# Initialize Redis with Lua scripts
init_redis() {
    echo "Initializing Redis..."
    
    # Load initialization script
    docker-compose -f docker-compose.db.yml exec -T redis redis-cli --eval /docker-entrypoint-initdb.d/init-redis.lua
    
    # Load cache helper scripts
    docker-compose -f docker-compose.db.yml exec -T redis redis-cli --eval /docker-entrypoint-initdb.d/cache-helpers.lua
    
    echo "✅ Redis initialized"
}

# Run database migrations
run_migrations() {
    echo "Running database migrations..."
    
    # PostgreSQL should auto-initialize from scripts in /docker-entrypoint-initdb.d
    # Additional migrations can be added here
    
    echo "✅ Migrations completed"
}

# Verify setup
verify_setup() {
    echo "Verifying database setup..."
    
    # Check PostgreSQL
    PG_CHECK=$(docker-compose -f docker-compose.db.yml exec -T postgresql psql -U ytempire_user -d ytempire_dev -c "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name IN ('users', 'content', 'analytics', 'campaigns');" -t -A 2>/dev/null || echo "0")
    
    if [ "$PG_CHECK" = "4" ]; then
        echo "✅ PostgreSQL schemas created successfully"
    else
        echo "❌ PostgreSQL setup incomplete. Schemas found: $PG_CHECK/4"
    fi
    
    # Check Redis
    REDIS_CHECK=$(docker-compose -f docker-compose.db.yml exec -T redis redis-cli EXISTS yt:cache:stats 2>/dev/null || echo "0")
    
    if [ "$REDIS_CHECK" = "1" ]; then
        echo "✅ Redis initialized successfully"
    else
        echo "❌ Redis setup incomplete"
    fi
}

# Display connection information
show_connection_info() {
    echo ""
    echo "======================================"
    echo "Database Connection Information"
    echo "======================================"
    echo ""
    echo "PostgreSQL:"
    echo "  Host: localhost"
    echo "  Port: 5432"
    echo "  Database: ytempire_dev"
    echo "  Username: ytempire_user"
    echo "  Password: ytempire_pass"
    echo "  URL: postgresql://ytempire_user:ytempire_pass@localhost:5432/ytempire_dev"
    echo ""
    echo "Redis:"
    echo "  Host: localhost"
    echo "  Port: 6379"
    echo "  URL: redis://localhost:6379/0"
    echo ""
    echo "pgAdmin:"
    echo "  URL: http://localhost:8080"
    echo "  Email: admin@ytempire.com"
    echo "  Password: admin123"
    echo ""
    echo "Redis Commander:"
    echo "  URL: http://localhost:8081"
    echo "  Username: admin"
    echo "  Password: admin123"
    echo ""
    echo "======================================"
}

# Main execution
main() {
    check_prerequisites
    create_directories
    setup_environment
    start_databases
    init_redis
    run_migrations
    verify_setup
    show_connection_info
    
    echo ""
    echo "✅ YTEmpire database setup completed successfully!"
    echo ""
    echo "To stop the databases: docker-compose -f docker-compose.db.yml down"
    echo "To view logs: docker-compose -f docker-compose.db.yml logs -f"
    echo ""
}

# Run main function
main "$@"