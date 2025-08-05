#!/bin/bash

# Backup YTEmpire development data

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Create timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="backups/$TIMESTAMP"

echo -e "${BLUE}Creating backup...${NC}"

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup PostgreSQL database
echo "Backing up PostgreSQL database..."
docker exec ytempire-postgresql pg_dump -U ytempire_user ytempire_dev > "$BACKUP_DIR/database.sql"

# Backup Redis data
echo "Backing up Redis data..."
docker exec ytempire-redis redis-cli BGSAVE
sleep 2
docker cp ytempire-redis:/data/dump.rdb "$BACKUP_DIR/redis-dump.rdb"

# Backup uploads directory
echo "Backing up uploads..."
if [ -d "uploads" ] && [ "$(ls -A uploads)" ]; then
    cp -r uploads "$BACKUP_DIR/"
fi

# Backup environment file
echo "Backing up environment configuration..."
cp .env "$BACKUP_DIR/.env.backup"

# Create backup info
cat > "$BACKUP_DIR/backup-info.txt" << EOF
YTEmpire Backup
Created: $(date)
Version: $(git rev-parse HEAD 2>/dev/null || echo "unknown")
Database: ytempire_dev
EOF

# Compress backup
echo "Compressing backup..."
tar -czf "backups/ytempire-backup-$TIMESTAMP.tar.gz" -C backups $TIMESTAMP
rm -rf "$BACKUP_DIR"

echo -e "${GREEN}Backup completed!${NC}"
echo "Backup saved to: backups/ytempire-backup-$TIMESTAMP.tar.gz"

# Clean old backups (keep last 7 days)
echo "Cleaning old backups..."
find backups -name "ytempire-backup-*.tar.gz" -mtime +7 -delete

echo -e "${GREEN}Done!${NC}"