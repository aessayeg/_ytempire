#!/bin/bash

# Restore YTEmpire from backup

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if backup file provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: No backup file specified${NC}"
    echo "Usage: ./scripts/restore.sh backups/ytempire-backup-TIMESTAMP.tar.gz"
    echo ""
    echo "Available backups:"
    ls -la backups/*.tar.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE=$1

if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}Error: Backup file not found: $BACKUP_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}WARNING: This will overwrite your current data!${NC}"
read -p "Are you sure you want to restore from backup? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

echo -e "${BLUE}Restoring from backup...${NC}"

# Create temp directory
TEMP_DIR="temp/restore_$(date +%s)"
mkdir -p $TEMP_DIR

# Extract backup
echo "Extracting backup..."
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

# Find the backup directory
BACKUP_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d | tail -1)

# Stop services
echo "Stopping services..."
docker-compose stop

# Restore PostgreSQL database
echo "Restoring PostgreSQL database..."
docker exec -i ytempire-postgresql psql -U ytempire_user -d postgres -c "DROP DATABASE IF EXISTS ytempire_dev;"
docker exec -i ytempire-postgresql psql -U ytempire_user -d postgres -c "CREATE DATABASE ytempire_dev;"
docker exec -i ytempire-postgresql psql -U ytempire_user ytempire_dev < "$BACKUP_DIR/database.sql"

# Restore Redis data
echo "Restoring Redis data..."
docker cp "$BACKUP_DIR/redis-dump.rdb" ytempire-redis:/data/dump.rdb
docker exec ytempire-redis redis-cli SHUTDOWN SAVE
docker-compose start redis

# Restore uploads
echo "Restoring uploads..."
if [ -d "$BACKUP_DIR/uploads" ]; then
    rm -rf uploads
    cp -r "$BACKUP_DIR/uploads" .
fi

# Restore environment file (optional)
read -p "Restore environment configuration? (yes/no): " restore_env
if [ "$restore_env" == "yes" ]; then
    cp "$BACKUP_DIR/.env.backup" .env
    echo "Environment configuration restored."
fi

# Clean up
rm -rf "$TEMP_DIR"

# Start services
echo "Starting services..."
docker-compose start

echo -e "${GREEN}Restore completed successfully!${NC}"
echo ""
echo "Services are starting up. Check status with: docker-compose ps"